<#
.SYNOPSIS
    Assemble le paquet desktop Windows « tout-en-un » de Soutrali (phase 2).

.DESCRIPTION
    Sortie : dist\Soutrali-win64\
      <exécutable>.exe + DLL Flutter   application compilée (release)
      backend\                         Laravel 13 + vendor + base SQLite pré-remplie
      runtime\php\                     PHP 8.3.36 x64 portable (aucune installation sur la cible)

    Puis archive : dist\Soutrali-win64.zip — décompressée sur un poste sans
    PHP, MySQL ni Flutter, l'exécutable démarre le backend local (port 8123)
    puis ouvre l'application. Aucune installation requise sur la cible.

    Prérequis pour la compilation : Visual Studio 2022 (chargeur « Développement
    C++ avec les composants par défaut ») + Flutter Windows. Sans Visual Studio,
    utilisez -SkipFlutter avec un build existant.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File desktop\build-package.ps1
    powershell -ExecutionPolicy Bypass -File desktop\build-package.ps1 -SkipFlutter
#>
param(
    [switch]$SkipFlutter,
    [switch]$SkipSeed
)

$ErrorActionPreference = 'Stop'

$root      = Split-Path -Parent $PSScriptRoot
$dist      = Join-Path $root 'dist\Soutrali-win64'
$port      = '8123'
$api       = "http://127.0.0.1:$port"
$phpVersion = '8.3.36'
$phpZipUrl = "https://downloads.php.net/~windows/releases/archives/php-$phpVersion-Win32-vs16-x64.zip"
$phpDir    = Join-Path $root 'desktop\runtime\php'
$phpZip    = Join-Path $root "desktop\runtime\php-$phpVersion-Win32-vs16-x64.zip"
$phpExe    = Join-Path $phpDir 'php.exe'

# --- 1/6 — Runtime PHP portable -------------------------------------------------
Write-Host '== 1/6 - Runtime PHP portable'
if (-not (Test-Path $phpExe)) {
    if (-not (Test-Path $phpZip)) {
        Write-Host "   Telechargement de PHP $phpVersion x64 (~33 Mo)..."
        Invoke-WebRequest -Uri $phpZipUrl -OutFile $phpZip -UseBasicParsing
    }
    Write-Host '   Decompression...'
    Expand-Archive -Path $phpZip -DestinationPath $phpDir -Force
}
Copy-Item (Join-Path $PSScriptRoot 'runtime\php.ini') (Join-Path $phpDir 'php.ini') -Force
Write-Host "   Pret : $phpExe"

# --- 2/6 — Application Flutter --------------------------------------------------
Write-Host '== 2/6 - Application Flutter (release Windows)'
$release = Join-Path $root 'app\build\windows\x64\runner\Release'
if (-not $SkipFlutter) {
    Push-Location (Join-Path $root 'app')
    try {
        flutter build windows --release "--dart-define=API_BASE_URL=$api"
    }
    finally {
        Pop-Location
    }
}

# --- 3/6 — Staging --------------------------------------------------------------
Write-Host '== 3/6 - Assemblage du dossier'
if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Force -Path $dist | Out-Null

if (Test-Path $release) {
    Copy-Item (Join-Path $release '*') $dist -Recurse -Force
    Write-Host '   Application Flutter copiee a la racine du paquet'
}
else {
    Write-Warning "Pas de build Windows ($release). Installez Visual Studio (chargeur Developpement C++), ou passez par un build existant. Le backend est assemble quand meme."
}

$be = Join-Path $dist 'backend'
New-Item -ItemType Directory -Force -Path $be, (Join-Path $dist 'runtime') | Out-Null
# robocopy : copie nettement plus rapide que Copy-Item pour vendor/ (~20 000 fichiers)
foreach ($dir in 'app', 'bootstrap', 'config', 'database', 'public', 'resources', 'routes', 'storage', 'vendor') {
    $src = Join-Path $root "backend\$dir"
    $dst = Join-Path $be $dir
    robocopy $src $dst /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy $dir a echoue ($LASTEXITCODE)" }
    $global:LASTEXITCODE = 0
}
foreach ($file in 'artisan', 'composer.json', 'composer.lock') {
    Copy-Item (Join-Path $root "backend\$file") $be -Force
}
Get-ChildItem (Join-Path $be 'storage\logs') -File -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force
Write-Host '   Backend copie (vendor inclus), journaux purges'

# Le paquet livre ne doit embarquer aucun outil de developpement (Pest, PHPStan,
# Pint, Faker). Si Composer est disponible, on reinstalle sans les dependances de
# dev ; sinon on le signale, le paquet reste fonctionnel mais plus lourd.
# Composer n'est pas toujours dans le PATH (installeur Windows = .phar) : on
# accepte aussi l'emplacement standard de l'installeur.
$composerPhar = Join-Path $env:LOCALAPPDATA 'Programs\Composer\composer.phar'
$composerCmd = $null
if (Get-Command composer -ErrorAction SilentlyContinue) { $composerCmd = 'composer' }
elseif (Test-Path $composerPhar) { $composerCmd = "php `"$composerPhar`"" }

if ($composerCmd) {
    Push-Location $be
    try {
        if ($composerCmd -eq 'composer') { & composer install --no-dev --optimize-autoloader --no-interaction }
        else { & php $composerPhar install --no-dev --optimize-autoloader --no-interaction }
        if ($LASTEXITCODE -ne 0) { throw "composer install --no-dev a echoue ($LASTEXITCODE)" }
        Write-Host '   vendor reinstalle sans les dependances de developpement'
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Warning "Composer introuvable : le vendor du paquet contient encore Pest, PHPStan, Pint et Faker. Installez Composer puis relancez, ou executez composer install --no-dev --working-dir=dist/Soutrali-win64/backend"
}

Copy-Item $phpDir (Join-Path $dist 'runtime\php') -Recurse -Force
Write-Host '   Runtime PHP copie'

# --- 4/6 — Configuration du paquet ---------------------------------------------
Write-Host '== 4/6 - Configuration (SQLite, aucun service externe)'
$envPath = Join-Path $be '.env'
@"
APP_NAME=Soutrali
APP_ENV=local
APP_KEY=
APP_DEBUG=false
APP_URL=$api
FRONTEND_URL=https://soutrali.com
APP_LOCALE=fr
APP_FALLBACK_LOCALE=fr
APP_FAKER_LOCALE=fr_FR
LOG_CHANNEL=stack
LOG_LEVEL=error
DB_CONNECTION=sqlite
CACHE_STORE=database
QUEUE_CONNECTION=sync
SESSION_DRIVER=database
SESSION_LIFETIME=120
SANCTUM_STATEFUL_DOMAINS=127.0.0.1:$port
MAIL_MAILER=log
MAIL_FROM_ADDRESS="no-reply@soutrali.local"
MAIL_FROM_NAME="Soutrali"
"@ | Set-Content -Path $envPath -Encoding UTF8
Write-Host "   .env ecrit (base : backend\database\database.sqlite, chemin absolu genere par Laravel)"

# --- 5/6 — Base SQLite pré-migrée (référentiel seulement) ----------------------
Write-Host '== 5/6 - Migrations et referentiel (aucun compte de demonstration)'
Push-Location $be
try {
    & $phpExe artisan key:generate --force
    if ($LASTEXITCODE -ne 0) { throw "key:generate a echoue ($LASTEXITCODE)" }
    & $phpExe artisan migrate --force
    if ($LASTEXITCODE -ne 0) { throw "migrate a echoue ($LASTEXITCODE)" }
    # Seul le referentiel (communes, categories) est seme : DemoSeeder cree des
    # comptes fictifs dont un administrateur au mot de passe « password » et ne
    # doit JAMAIS partir dans un livrable. L'administrateur se cree a la premiere
    # utilisation : php artisan soutrali:create-admin <email> (saisie masquee).
    if (-not $SkipSeed) {
        & $phpExe artisan db:seed --class=CommuneSeeder --force
        if ($LASTEXITCODE -ne 0) { throw "db:seed CommuneSeeder a echoue ($LASTEXITCODE)" }
        & $phpExe artisan db:seed --class=CategorySeeder --force
        if ($LASTEXITCODE -ne 0) { throw "db:seed CategorySeeder a echoue ($LASTEXITCODE)" }
    }
    & $phpExe artisan config:clear | Out-Null
}
finally {
    Pop-Location
}

# --- 6/6 — Archive --------------------------------------------------------------
Write-Host '== 6/6 - Archive'
$zip = Join-Path $root 'dist\Soutrali-win64.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
# tar.exe (bsdtar, natif Windows 10+) : bien plus rapide que Compress-Archive
# sur les ~20 000 fichiers du vendor, et compatible ZIP via l'extension.
# Chemin absolu obligatoire : dans un shell Git, le `tar` de Git Bash est
# prioritaire et interprete « C: » comme un hote distant.
$tarExe = Join-Path $env:SystemRoot 'System32\tar.exe'
if (-not (Test-Path $tarExe)) { $tarExe = 'tar' }
& $tarExe -a -c -f $zip -C (Join-Path $root 'dist') 'Soutrali-win64'
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $zip)) {
    Write-Warning 'Archive par tar impossible : repli sur Compress-Archive (plus lent)'
    Compress-Archive -Path (Join-Path $dist '*') -DestinationPath $zip -CompressionLevel Optimal
}
$size = [math]::Round((Get-Item $zip).Length / 1MB, 1)

Write-Host ''
Write-Host "Paquet  : $dist"
Write-Host "Archive : $zip ($size Mo)"
Write-Host "Sur la cible : dezipper et double-cliquer sur l'executable ;"
Write-Host "  il demarre le backend local ($api) puis ouvre l'application."
