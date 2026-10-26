<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    /**
     * Référentiel des services (catégories) : les 8 catégories validées par
     * le porteur le 22 octobre 2026 (D-07), étendues le 26 octobre 2026 à
     * la liste complète des services proposables sur Soutrali.
     *
     * @var array<string, string>
     */
    public const NAMES = [
        // — Catégories initiales validées (D-07) —
        'Réparations et dépannage' => 'Réparation d’objets, d’électroménager, de téléphones et petits dépannages.',
        'Maison et domestique' => 'Ménage, repassage, petite maintenance et coups de main à la maison.',
        'Couture, beauté et coiffure' => 'Couture, retouches, coiffure et services de mise en beauté.',
        'Éducation et cours' => 'Cours particuliers, soutien scolaire et aide à la formation.',
        'Informatique et numérique' => 'Dépannage informatique, installation, initiation et aide numérique.',
        'Transport léger et déménagement' => 'Transport d’objets, aide au déménagement et petites livraisons.',
        'Petites missions et coups de main' => 'Missions ponctuelles, courses, assistance et coups de main du quotidien.',
        'Autres' => 'Besoins et offres qui ne relèvent d’aucune autre catégorie.',

        // — Extension du 26 octobre 2026 : liste complète des services —
        'Plomberie et sanitaire' => 'Fuites, robinetterie, sanitaires et installations d’eau à domicile.',
        'Électricité et éclairage' => 'Tableaux, prises, luminaires et dépannage électrique.',
        'Menuiserie et mobilier' => 'Meubles, portes, fenêtres, montage et réparation de mobilier.',
        'Peinture et décoration' => 'Peinture intérieure, enduits, papier peint et décoration de pièces.',
        'Maçonnerie et carrelage' => 'Travaux de maçonnerie, carrelage, faïence et dallage.',
        'Jardinage et espaces verts' => 'Tonte, taille, entretien de jardin et plantation.',
        'Garde d’enfants' => 'Garde d’enfants, sortie d’école et aide aux devoirs du quotidien.',
        'Aide aux personnes âgées' => 'Accompagnement, courses et présence auprès des personnes âgées.',
        'Cuisine et traiteur' => 'Repas, pâtisserie, plats familiaux et service de traiteur.',
        'Santé et bien-être' => 'Massage, hygiène à domicile et accompagnement bien-être de proximité.',
        'Sport et coaching' => 'Coaching, entraînement, cours de sport et activité physique.',
        'Photographie et vidéo' => 'Reportage photo, portraits et montage vidéo pour événements.',
        'Événements et animation' => 'Mariages, anniversaires, sonorisation et décoration de fête.',
        'Mécanique et automobile' => 'Entretien, pneumatique, batterie et dépannage de véhicules.',
        'Livraison et courses' => 'Livraison de repas, courses et petits colis dans la ville.',
        'Comptabilité et gestion' => 'Tenue de comptes, facturation, bulletins et aide à la gestion.',
        'Droit et démarches' => 'Conseil juridique, contrats, lettres et accompagnement administratif.',
        'Langues et traduction' => 'Cours de langues, traduction et relecture de documents.',
        'Sécurité et surveillance' => 'Gardiennage, tournées et installation d’équipements de sécurité.',
        'Animaux domestiques' => 'Toilettage, garde et promenade d’animaux.',
        'Musique et arts' => 'Cours de musique, animation musicale, dessin et création artistique.',
        'Communication et marketing' => 'Logos, affiches, réseaux sociaux et supports de communication.',
        'Vente et petit commerce' => 'Vente de produits, revente et micro-commerce de proximité.',
        'Agriculture et élevage' => 'Maraîchage, petites cultures, volaille et produits du jardin.',
    ];

    /**
     * Icône de chaque service (clé lisible par l'application, voir
     * `Category::ICONS`). Les mêmes clés que `NAMES`, dans le même ordre.
     *
     * @var array<string, string>
     */
    public const ICONS = [
        'Réparations et dépannage' => 'repair',
        'Maison et domestique' => 'house',
        'Couture, beauté et coiffure' => 'beauty',
        'Éducation et cours' => 'education',
        'Informatique et numérique' => 'digital',
        'Transport léger et déménagement' => 'moving',
        'Petites missions et coups de main' => 'help',
        'Autres' => 'misc',
        'Plomberie et sanitaire' => 'plumbing',
        'Électricité et éclairage' => 'electricity',
        'Menuiserie et mobilier' => 'carpentry',
        'Peinture et décoration' => 'painting',
        'Maçonnerie et carrelage' => 'masonry',
        'Jardinage et espaces verts' => 'gardening',
        'Garde d’enfants' => 'childcare',
        'Aide aux personnes âgées' => 'elderly',
        'Cuisine et traiteur' => 'catering',
        'Santé et bien-être' => 'health',
        'Sport et coaching' => 'sport',
        'Photographie et vidéo' => 'photo',
        'Événements et animation' => 'events',
        'Mécanique et automobile' => 'auto',
        'Livraison et courses' => 'delivery',
        'Comptabilité et gestion' => 'business',
        'Droit et démarches' => 'legal',
        'Langues et traduction' => 'languages',
        'Sécurité et surveillance' => 'security',
        'Animaux domestiques' => 'pets',
        'Musique et arts' => 'arts',
        'Communication et marketing' => 'marketing',
        'Vente et petit commerce' => 'commerce',
        'Agriculture et élevage' => 'agriculture',
    ];

    public function run(): void
    {
        foreach (self::NAMES as $name => $description) {
            Category::firstOrCreate(
                ['name' => $name],
                [
                    'description' => $description,
                    'icon' => self::ICONS[$name] ?? 'misc',
                    'active' => true,
                ],
            );
        }

        // Une catégorie déjà en base (avant la colonne `icon`) reçoit son
        // icône : le seeder doit rester rejouable sur une base existante.
        foreach (self::ICONS as $name => $icon) {
            Category::where('name', $name)
                ->where(fn ($query) => $query->whereNull('icon')->orWhere('icon', 'misc'))
                ->where('name', '!=', 'Autres')
                ->update(['icon' => $icon]);
        }
    }
}
