<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Commune;
use App\Models\Listing;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/**
 * Vitrine des services (7 nov. 2026, complétée le 8) : chaque service actif
 * reçoit **de une à cinq annonces publiées**, pour qu'aucune pastille de
 * « Tous les services » ne mène à une liste vide ou à une annonce unique.
 *
 * Le nombre cible est tiré au sort **une fois pour toutes** à partir du nom
 * du service (`targetFor`) : 1 à 5 annonces, stables d'un rejeu à l'autre,
 * donc le seeder reste idempotent et ne crée jamais de doublon. Les annonces
 * supplémentaires varient par le quartier, le budget et un préfixe de titre,
 * et restent dans la commune et le texte de l'entrée de catalogue pour ne pas
 * se contredire.
 *     * Il ne touche jamais aux annonces réelles : il ne fait qu'ajouter des
     * annonces du compte « Équipe Soutrali », créé au besoin, et seulement
     * tant que le service n'atteint pas sa cible.
 */
class ShowcaseSeeder extends Seeder
{
    public const AUTHOR_EMAIL = 'equipe@soutrali.ci';

    /**
     * Une annonce par service du référentiel (`CategorySeeder::NAMES`).
     *
     * @var array<string, array<string, mixed>>
     */
    public const CATALOGUE = [
        'Réparations et dépannage' => [
            'title' => 'Réparation de ventilateurs et de petits électroménagers',
            'description' => 'Je répare ventilateurs, mixeurs et fers à repasser à domicile, diagnostic offert et devis avant intervention. Je me déplace dans tout Yopougon.',
            'commune' => 'Yopougon',
            'quartier' => 'Niangon',
            'nature' => 'REMUNEREE',
            'budget' => 5000,
            'availability' => 'Du lundi au samedi, après 15 h',
        ],
        'Maison et domestique' => [
            'title' => 'Ménage et repassage à domicile',
            'description' => 'Entretien complet d’un appartement (deux à quatre pièces) : sols, sanitaires, cuisine et repassage du linge de la semaine.',
            'commune' => 'Marcory',
            'quartier' => 'Anoumabo',
            'nature' => 'REMUNEREE',
            'budget' => 7000,
            'availability' => 'Le samedi matin',
        ],
        'Couture, beauté et coiffure' => [
            'title' => 'Retouches et ourlets rendus en 48 h',
            'description' => 'Ourlets de pantalons, fermetures éclair, retouches de robes et uniformes, avec essayage au marché de Treichville.',
            'commune' => 'Treichville',
            'quartier' => 'Marché de Treichville',
            'nature' => 'REMUNEREE',
            'budget' => 3000,
            'availability' => 'Du lundi au vendredi',
        ],
        'Éducation et cours' => [
            'title' => 'Soutien scolaire en maths pour la 3e',
            'description' => 'Reprise des bases, exercices corrigés et préparation au BEPC, deux séances par semaine à domicile ou en petit groupe.',
            'commune' => 'Cocody',
            'quartier' => 'Angré',
            'nature' => 'REMUNEREE',
            'budget' => 10000,
            'availability' => 'Mercredi et samedi',
        ],
        'Informatique et numérique' => [
            'title' => 'Dépannage d’ordinateur et installation à domicile',
            'description' => 'Nettoyage, réinstallation de Windows, sauvegarde des fichiers et installation d’une imprimante ou d’un routeur.',
            'commune' => 'Plateau',
            'quartier' => 'Plateau Centre',
            'nature' => 'REMUNEREE',
            'budget' => 8000,
            'availability' => 'Sur rendez-vous, en journée',
        ],
        'Transport léger et déménagement' => [
            'title' => 'Déménagement d’un studio le samedi',
            'description' => 'Camionnette, deux porteurs et couvertures de protection pour déménager un studio d’Adjamé vers une autre commune.',
            'commune' => 'Adjamé',
            'quartier' => 'Liberté',
            'nature' => 'REMUNEREE',
            'budget' => 20000,
            'availability' => 'Samedi toute la journée',
        ],
        'Petites missions et coups de main' => [
            'title' => 'Coup de main pour monter un meuble',
            'description' => 'Montage d’une armoire ou d’un lit, avec outillage fourni. Mission d’une à deux heures, gratuite pour un voisin du quartier.',
            'commune' => 'Koumassi',
            'quartier' => 'Remblais',
            'nature' => 'BENEVOLE',
            'budget' => null,
            'availability' => 'En fin de journée',
        ],
        'Autres' => [
            'title' => 'Accompagnement pour une démarche à la mairie',
            'description' => 'Je vous accompagne pour constituer un dossier et faire la queue à la mairie d’Abobo, avec toutes les pièces vérifiées avant.',
            'commune' => 'Abobo',
            'quartier' => 'Abobo Centre',
            'nature' => 'BENEVOLE',
            'budget' => null,
            'availability' => 'Les mardis et jeudis matin',
        ],
        'Plomberie et sanitaire' => [
            'title' => 'Fuite sous l’évier : intervention rapide',
            'description' => 'Recherche de fuite, remplacement de siphon et de joint, remise en service de l’eau dans la journée.',
            'commune' => 'Yopougon',
            'quartier' => 'Sicogi',
            'nature' => 'REMUNEREE',
            'budget' => 6000,
            'availability' => 'Tous les jours, 8 h – 19 h',
        ],
        'Électricité et éclairage' => [
            'title' => 'Installation d’un tableau électrique',
            'description' => 'Mise aux normes d’un tableau, pose de disjoncteurs et étiquetage des circuits, avec essai complet.',
            'commune' => 'Abobo',
            'quartier' => 'Abobo Baoulé',
            'nature' => 'REMUNEREE',
            'budget' => 25000,
            'availability' => 'Sur rendez-vous',
        ],
        'Menuiserie et mobilier' => [
            'title' => 'Fabrication d’une étagère sur mesure',
            'description' => 'Étagère en bois massif prise de mesures à domicile, finition vernie, livrée et posée en une semaine.',
            'commune' => 'Yopougon',
            'quartier' => 'Toits Rouges',
            'nature' => 'REMUNEREE',
            'budget' => 20000,
            'availability' => 'Livraison sous 7 jours',
        ],
        'Peinture et décoration' => [
            'title' => 'Peinture d’un salon en deux jours',
            'description' => 'Protection du mobilier, rebouchage, deux couches et nettoyage final. Devis au mètre carré, peinture au choix.',
            'commune' => 'Marcory',
            'quartier' => 'Zone 4',
            'nature' => 'REMUNEREE',
            'budget' => 35000,
            'availability' => 'Week-end ou jours libres',
        ],
        'Maçonnerie et carrelage' => [
            'title' => 'Réparation d’un mur et pose de carrelage',
            'description' => 'Reprise d’un mur fissuré, enduit et pose de carrelage dans une cuisine ou une salle de bain.',
            'commune' => 'Koumassi',
            'quartier' => 'Zone industrielle',
            'nature' => 'REMUNEREE',
            'budget' => 40000,
            'availability' => 'Chantier de trois à cinq jours',
        ],
        'Jardinage et espaces verts' => [
            'title' => 'Entretien de jardin et taille de haies',
            'description' => 'Tonte, désherbage, taille des haies et évacuation des déchets verts, une fois par mois ou à la demande.',
            'commune' => 'Cocody',
            'quartier' => 'Riviera 3',
            'nature' => 'REMUNEREE',
            'budget' => 15000,
            'availability' => 'Samedi matin',
        ],
        'Garde d’enfants' => [
            'title' => 'Garde d’enfants après l’école',
            'description' => 'Récupération à la sortie de l’école, goûter, aide aux devoirs et garde jusqu’au retour des parents, du lundi au vendredi.',
            'commune' => 'Cocody',
            'quartier' => 'Deux-Plateaux',
            'nature' => 'REMUNEREE',
            'budget' => 4000,
            'availability' => 'En semaine, 16 h – 19 h',
        ],
        'Aide aux personnes âgées' => [
            'title' => 'Courses et compagnie pour une personne âgée',
            'description' => 'Je fais les courses, j’accompagne aux rendez-vous et je reste un moment pour discuter, deux fois par semaine.',
            'commune' => 'Adjamé',
            'quartier' => 'Bracodi',
            'nature' => 'BENEVOLE',
            'budget' => null,
            'availability' => 'Lundi et jeudi matin',
        ],
        'Cuisine et traiteur' => [
            'title' => 'Repas de fête pour vingt personnes',
            'description' => 'Menu ivoirien complet (attieké, poisson braisé, alloco et dessert), cuisiné et livré chaud pour un anniversaire.',
            'commune' => 'Yopougon',
            'quartier' => 'Wassa',
            'nature' => 'REMUNEREE',
            'budget' => 45000,
            'availability' => 'Sur commande, 48 h à l’avance',
        ],
        'Santé et bien-être' => [
            'title' => 'Massage de détente à domicile',
            'description' => 'Séance d’une heure à domicile, huiles naturelles fournies, sur rendez-vous en fin de journée ou le week-end.',
            'commune' => 'Cocody',
            'quartier' => 'Blockhaus',
            'nature' => 'REMUNEREE',
            'budget' => 12000,
            'availability' => 'Sur rendez-vous',
        ],
        'Sport et coaching' => [
            'title' => 'Coach sportif pour débutants au parc',
            'description' => 'Remise en forme progressive en petit groupe au parc de la Riviera : échauffement, renforcement et étirements.',
            'commune' => 'Cocody',
            'quartier' => 'Riviera 1',
            'nature' => 'REMUNEREE',
            'budget' => 8000,
            'availability' => 'Mardi et jeudi, 6 h 30',
        ],
        'Photographie et vidéo' => [
            'title' => 'Reportage photo d’anniversaire',
            'description' => 'Deux heures de reportage, retouche des photos et livraison d’une galerie en ligne sous trois jours.',
            'commune' => 'Marcory',
            'quartier' => 'Marcory Centre',
            'nature' => 'REMUNEREE',
            'budget' => 30000,
            'availability' => 'Week-end',
        ],
        'Événements et animation' => [
            'title' => 'Sonorisation pour une soirée de quartier',
            'description' => 'Sonorisation, micros et éclairage pour une soirée de quartier, installation et démontage compris.',
            'commune' => 'Treichville',
            'quartier' => 'Arras',
            'nature' => 'REMUNEREE',
            'budget' => 25000,
            'availability' => 'Vendredi et samedi soir',
        ],
        'Mécanique et automobile' => [
            'title' => 'Diagnostic et vidange à domicile',
            'description' => 'Vidange, contrôle des freins et batterie sur place, avec rapport des points à surveiller avant le prochain contrôle.',
            'commune' => 'Yopougon',
            'quartier' => 'Selmer',
            'nature' => 'REMUNEREE',
            'budget' => 15000,
            'availability' => 'Tous les jours, 9 h – 18 h',
        ],
        'Livraison et courses' => [
            'title' => 'Livraison de colis dans tout Abidjan',
            'description' => 'Course ou colis récupéré dans une commune et livré dans une autre le jour même, suivi par message.',
            'commune' => 'Adjamé',
            'quartier' => 'Adjamé Centre',
            'nature' => 'REMUNEREE',
            'budget' => 2000,
            'availability' => 'Du lundi au samedi',
        ],
        'Comptabilité et gestion' => [
            'title' => 'Tenue de caisse d’une petite boutique',
            'description' => 'Mise en place d’un cahier de caisse, suivi des recettes et dépenses, et bilan mensuel simple.',
            'commune' => 'Plateau',
            'quartier' => 'Cité Administrative',
            'nature' => 'REMUNEREE',
            'budget' => 20000,
            'availability' => 'Une fois par semaine',
        ],
        'Droit et démarches' => [
            'title' => 'Rédaction d’une lettre de réclamation',
            'description' => 'Rédaction et relecture d’une lettre de réclamation ou d’un contrat de location, avec les pièces à joindre.',
            'commune' => 'Plateau',
            'quartier' => 'Plateau Centre',
            'nature' => 'REMUNEREE',
            'budget' => 5000,
            'availability' => 'Sur rendez-vous',
        ],
        'Langues et traduction' => [
            'title' => 'Cours d’anglais par conversation',
            'description' => 'Séances d’une heure axées sur la conversation, pour adultes et lycéens, à domicile ou en visioconférence.',
            'commune' => 'Cocody',
            'quartier' => 'Angré',
            'nature' => 'REMUNEREE',
            'budget' => 10000,
            'availability' => 'Mercredi et dimanche',
        ],
        'Sécurité et surveillance' => [
            'title' => 'Gardiennage de nuit pour un chantier',
            'description' => 'Présence de nuit et rondes régulières sur un chantier ou un magasin, du dimanche au jeudi.',
            'commune' => 'Abobo',
            'quartier' => 'PK18',
            'nature' => 'REMUNEREE',
            'budget' => 25000,
            'availability' => 'Nuit, 19 h – 6 h',
        ],
        'Animaux domestiques' => [
            'title' => 'Toilettage de chiens et de chats',
            'description' => 'Bain, brossage et coupe des griffes à domicile, pour animaux de petite et moyenne taille.',
            'commune' => 'Cocody',
            'quartier' => 'Deux-Plateaux',
            'nature' => 'REMUNEREE',
            'budget' => 5000,
            'availability' => 'Sur rendez-vous, le week-end',
        ],
        'Musique et arts' => [
            'title' => 'Cours de dessin pour enfants',
            'description' => 'Atelier de dessin et de peinture pour les enfants du quartier, matériel fourni, mercredi après-midi.',
            'commune' => 'Treichville',
            'quartier' => 'Marché de Treichville',
            'nature' => 'BENEVOLE',
            'budget' => null,
            'availability' => 'Mercredi après-midi',
        ],
        'Communication et marketing' => [
            'title' => 'Logo et carte de visite pour un commerce',
            'description' => 'Création d’un logo, d’une carte de visite et d’une bannière pour les réseaux sociaux, trois propositions.',
            'commune' => 'Cocody',
            'quartier' => 'Angré',
            'nature' => 'REMUNEREE',
            'budget' => 15000,
            'availability' => 'Livraison sous 5 jours',
        ],
        'Vente et petit commerce' => [
            'title' => 'Vente de tissus wax et de pagnes',
            'description' => 'Wax et bazin en petite et grande largeur, choix sur place, retouches possibles chez la couturière du marché.',
            'commune' => 'Treichville',
            'quartier' => 'Marché de Treichville',
            'nature' => 'REMUNEREE',
            'budget' => null,
            'availability' => 'Du lundi au samedi',
        ],
        'Agriculture et élevage' => [
            'title' => 'Plants de tomate et piment du jardin',
            'description' => 'Plants de tomate, piment et manioc cultivés à Songon, livrés en godets prêts à repiquer.',
            'commune' => 'Songon',
            'quartier' => 'Adiapodoumé',
            'nature' => 'REMUNEREE',
            'budget' => null,
            'availability' => 'Le samedi matin',
        ],
    ];

    /**
     * Préfixes des annonces supplémentaires d'un même service. La première
     * annonce garde le titre du catalogue (préfixe vide).
     *
     * @var list<string>
     */
    private const EXTRA_PREFIXES = [
        '',
        'À domicile : ',
        'Express : ',
        'Sur rendez-vous : ',
        'Petit budget : ',
    ];

    /**
     * Quartiers réels par commune, pour que les annonces supplémentaires d'un
     * même service ne se ressemblent pas toutes.
     *
     * @var array<string, list<string>>
     */
    private const NEIGHBORHOODS = [
        'Abobo' => ['Abobo Centre', 'Abobo Baoulé', 'PK18'],
        'Adjamé' => ['Adjamé Centre', 'Liberté', 'Bracodi'],
        'Anyama' => ['Anyama Centre', 'Abobo-Doumé'],
        'Attécoubé' => ['Locodjro', 'Santé'],
        'Bingerville' => ['Bingerville Centre', 'Adjamé-Bingerville'],
        'Cocody' => ['Angré', 'Riviera 3', 'Deux-Plateaux', 'Blockhaus'],
        'Koumassi' => ['Remblais', 'Zone industrielle', 'Grand Marché'],
        'Marcory' => ['Anoumabo', 'Zone 4', 'Marcory Centre'],
        'Plateau' => ['Plateau Centre', 'Cité Administrative'],
        'Port-Bouët' => ['Port-Bouët Centre', 'Vridi'],
        'Songon' => ['Adiapodoumé', 'Songon-Agbanou'],
        'Treichville' => ['Arras', 'Marché de Treichville'],
        'Yopougon' => ['Niangon', 'Sicogi', 'Toits Rouges', 'Wassa'],
    ];

    /**
     * Nombre d'annonces vitrine d'un service : **entre 1 et 5**, tiré du nom
     * du service pour rester stable d'un rejeu à l'autre.
     */
    public static function targetFor(string $categoryName): int
    {
        return (crc32($categoryName) % 5) + 1;
    }

    public function run(): void
    {
        $author = User::firstOrCreate(
            ['email' => self::AUTHOR_EMAIL],
            [
                'display_name' => 'Équipe Soutrali',
                'password' => Str::random(40),
                'role' => 'UTILISATEUR',
                'status' => 'ACTIF',
                'presentation' => 'Compte de la vitrine Soutrali : annonces de démonstration, de une à cinq par service.',
            ],
        );

        $created = 0;

        foreach (self::CATALOGUE as $categoryName => $entry) {
            $category = Category::where('name', $categoryName)->first();
            $commune = Commune::where('name', $entry['commune'])->first();

            if ($category === null || $commune === null) {
                continue;
            }

            // On compte toutes les annonces publiées du service, réelles
            // comprises, pour que le total reste entre 1 et 5 : si un
            // visiteur a déjà publié, la vitrine complète sans dépasser.
            $existing = Listing::query()
                ->where('category_id', $category->id)
                ->published()
                ->count();

            $target = self::targetFor($categoryName);

            for ($index = $existing; $index < $target; $index++) {
                Listing::create($this->attributes($author, $category, $commune, $entry, $index));
                $created++;
            }
        }

        if ($created > 0) {
            $this->command?->info("Vitrine : {$created} annonce(s) ajoutée(s) aux services.");
        }
    }

    /**
     * Attributs d'une annonce vitrine. L'index 0 est l'annonce du catalogue ;
     * les suivantes changent de quartier, de budget et de préfixe de titre,
     * sans quitter la commune citée dans le texte.
     *
     * @param  array<string, mixed>  $entry
     * @return array<string, mixed>
     */
    private function attributes(
        User $author,
        Category $category,
        Commune $commune,
        array $entry,
        int $index,
    ): array {
        $neighborhoods = self::NEIGHBORHOODS[$commune->name] ?? [$entry['quartier']];
        $prefix = self::EXTRA_PREFIXES[$index % count(self::EXTRA_PREFIXES)];

        return [
            'user_id' => $author->id,
            'category_id' => $category->id,
            'commune_id' => $commune->id,
            'title' => $prefix.$entry['title'],
            'description' => $entry['description'],
            'type' => 'OFFRE',
            'nature' => $entry['nature'],
            'neighborhood' => $neighborhoods[$index % count($neighborhoods)],
            'availability' => $entry['availability'],
            'budget' => self::budget($entry['budget'], $index),
            'status' => 'PUBLIEE',
        ];
    }

    /**
     * Budget légèrement dégressif d'une annonce à l'autre (100 %, 95 %, 90 %…),
     * arrondi à 500 FCFA pour rester crédible.
     */
    private static function budget(?int $budget, int $index): ?int
    {
        if ($budget === null) {
            return null;
        }

        $amount = (int) (round($budget * (1 - 0.05 * $index) / 500) * 500);

        return max(1000, $amount);
    }
}
