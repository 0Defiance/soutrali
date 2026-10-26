<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Commune;
use App\Models\Interaction;
use App\Models\Listing;
use App\Models\Message;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Données de démonstration strictement locales (environnement local uniquement).
 *
 * Tous les contenus sont fictifs : aucun nom, numéro ni adresse réel.
 * Les deux comptes servent au tir d'essai T1b et aux recettes ; ils ne
 * doivent jamais être chargés en préproduction ni en production.
 */
class DemoSeeder extends Seeder
{
    public function run(): void
    {
        $koffi = User::firstOrCreate(
            ['email' => 'koffi.demo@soutrali.test'],
            [
                'display_name' => 'Koffi (compte de test)',
                'password' => 'password',
                'commune_id' => Commune::where('name', 'Yopougon')->value('id'),
                'presentation' => 'Compte de démonstration local — aucune donnée réelle.',
            ],
        );

        $awa = User::firstOrCreate(
            ['email' => 'awa.demo@soutrali.test'],
            [
                'display_name' => 'Awa (compte de test)',
                'password' => 'password',
                'commune_id' => Commune::where('name', 'Cocody')->value('id'),
                'presentation' => 'Compte de démonstration local — aucune donnée réelle.',
            ],
        );

        // Administrateur du back-office /admin (accès : MODERATEUR ou
        // ADMINISTRATEUR, voir User::canAccessPanel). Local uniquement.
        User::firstOrCreate(
            ['email' => 'admin.demo@soutrali.test'],
            [
                'display_name' => 'Admin (compte de test)',
                'password' => 'password',
                'role' => 'ADMINISTRATEUR',
                'commune_id' => Commune::where('name', 'Plateau')->value('id'),
                'presentation' => 'Compte de démonstration du back-office /admin — aucune donnée réelle.',
            ],
        );

        $listings = [
            [
                'title' => 'Réparer un ventilateur de plafond',
                'description' => 'Mon ventilateur de plafond ne démarre plus. Je cherche une personne capable de le diagnostiquer et de le réparer à domicile cette semaine.',
                'type' => 'DEMANDE',
                'nature' => 'REMUNEREE',
                'commune' => 'Yopougon',
                'category' => 'Réparations et dépannage',
                'neighborhood' => 'Niangon',
                'availability' => 'En semaine, après 16 h',
                'budget' => 5000,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Cours de mathématiques pour la 3e',
                'description' => 'Mon fils est en classe de 3e et a besoin d’un soutien hebdomadaire en mathématiques jusqu’aux examens.',
                'type' => 'DEMANDE',
                'nature' => 'REMUNEREE',
                'commune' => 'Cocody',
                'category' => 'Éducation et cours',
                'neighborhood' => 'Riviera 3',
                'availability' => 'Samedi et mercredi après-midi',
                'budget' => 10000,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Aide au déménagement un samedi',
                'description' => 'Je dois transporter quelques meubles d’un appartement à un autre dans le même quartier. Deux personnes pour quelques heures suffiraient.',
                'type' => 'DEMANDE',
                'nature' => 'BENEVOLE',
                'commune' => 'Marcory',
                'category' => 'Transport léger et déménagement',
                'neighborhood' => 'Zone 4',
                'availability' => 'Samedi matin',
                'budget' => null,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Reprise et retouche de vêtements',
                'description' => 'Couturière expérimentée, je propose retouches, ourlets et reprises de vêtements à domicile ou en atelier.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Treichville',
                'category' => 'Couture, beauté et coiffure',
                'neighborhood' => 'Marché',
                'availability' => 'Du lundi au samedi, 8 h – 18 h',
                'budget' => null,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Dépannage informatique à domicile',
                'description' => 'Installation, nettoyage, dépannage de PC et de téléphones : je me déplace dans ma commune et aux alentours.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Adjamé',
                'category' => 'Informatique et numérique',
                'neighborhood' => 'Libreville',
                'availability' => 'Tous les jours sauf dimanche',
                'budget' => null,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Coup de main pour les courses',
                'description' => 'Un voisin de passage souhaite aider une personne âgée à faire ses courses une fois par semaine, gratuitement.',
                'type' => 'OFFRE',
                'nature' => 'BENEVOLE',
                'commune' => 'Abobo',
                'category' => 'Petites missions et coups de main',
                'neighborhood' => 'Sogefiha',
                'availability' => 'Le mercredi matin',
                'budget' => null,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Ménage et repassage ponctuels',
                'description' => 'Je propose ménage complet et repassage pour les foyers de mon quartier, à la journée ou à la demi-journée.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Yopougon',
                'category' => 'Maison et domestique',
                'neighborhood' => 'Ananeraie',
                'availability' => 'Lundi, mercredi et vendredi',
                'budget' => null,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Cherche aide pour monter une étagère',
                'description' => 'J’ai acheté une étagère à monter et je ne suis pas à l’aise avec l’outillage. Un peu d’aide le week-end serait bienvenue.',
                'type' => 'DEMANDE',
                'nature' => 'BENEVOLE',
                'commune' => 'Cocody',
                'category' => 'Autres',
                'neighborhood' => 'Angré',
                'availability' => 'Week-end',
                'budget' => null,
                'user_id' => $awa->id,
            ],

            // — Jeu réaliste ajouté le 26 octobre 2026 : un aperçu par
            // service, pour tester les filtres et les icônes avec des
            // données crédibles. Aucune donnée réelle, tout est fictif.
            [
                'title' => 'Fuite sous l’évier de la cuisine',
                'description' => 'L’eau coule sous l’évier depuis deux jours et le meuble commence à gonfler. Recherche un plombier capable de passer cette semaine.',
                'type' => 'DEMANDE',
                'nature' => 'REMUNEREE',
                'commune' => 'Koumassi',
                'category' => 'Plomberie et sanitaire',
                'neighborhood' => 'Sicogi',
                'availability' => 'En semaine, après 17 h',
                'budget' => 8000,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Pose de prises et remplacement d’un disjoncteur',
                'description' => 'Mon disjoncteur saute dès qu’on branche le fer à repasser. Il faut aussi ajouter deux prises dans le salon.',
                'type' => 'DEMANDE',
                'nature' => 'REMUNEREE',
                'commune' => 'Abobo',
                'category' => 'Électricité et éclairage',
                'neighborhood' => 'Paillette',
                'availability' => 'Samedi matin',
                'budget' => 6000,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Montage de cuisine et pose de crédence',
                'description' => 'Je monte et j’installe les meubles de cuisine, je pose la crédence et je remets les prises en conformité. Devis gratuit sur place.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Cocody',
                'category' => 'Menuiserie et mobilier',
                'neighborhood' => 'Riviera 2',
                'availability' => 'Du lundi au samedi, 8 h – 17 h',
                'budget' => null,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Peinture d’un appartement trois pièces',
                'description' => 'Je propose peinture intérieure complète : ponce, enduit, deux couches. Matériel fourni, chantier mené en trois jours.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Marcory',
                'category' => 'Peinture et décoration',
                'neighborhood' => 'Zone 4',
                'availability' => 'Trois jours à convenir',
                'budget' => 85000,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Carrelage de la terrasse',
                'description' => 'Ma terrasse est en béton brut : je cherche un carreleur pour environ 25 m², matériaux déjà achetés.',
                'type' => 'DEMANDE',
                'nature' => 'REMUNEREE',
                'commune' => 'Anyama',
                'category' => 'Maçonnerie et carrelage',
                'neighborhood' => 'Centre',
                'availability' => 'Fin de semaine',
                'budget' => 45000,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Entretien de jardin deux fois par mois',
                'description' => 'J’entretiens les jardins de mon quartier : tonte, taille des haies, désherbage et nettoyage des allées.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Bingerville',
                'category' => 'Jardinage et espaces verts',
                'neighborhood' => 'Centre',
                'availability' => 'Deux samedis par mois',
                'budget' => 12000,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Garde des enfants après l’école',
                'description' => 'Je cherche quelqu’un de confiance pour récupérer mes deux enfants à 15 h et surveiller leurs devoirs jusqu’à 18 h.',
                'type' => 'DEMANDE',
                'nature' => 'REMUNEREE',
                'commune' => 'Yopougon',
                'category' => 'Garde d’enfants',
                'neighborhood' => 'Niangon',
                'availability' => 'Du lundi au vendredi, 15 h – 18 h',
                'budget' => 15000,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Repas familiaux livrés le soir',
                'description' => 'Plats du jour mijotés, livrés chauds entre 18 h et 20 h : attiéké-poisson, poulet DG, garba. Menu annoncé la veille.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Adjamé',
                'category' => 'Cuisine et traiteur',
                'neighborhood' => 'Libreville',
                'availability' => 'Du dimanche au jeudi',
                'budget' => null,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Massage et étirements à domicile',
                'description' => 'Kinésithérapeute de formation, je propose séances de détente et d’étirement après le travail, chez vous ou en cabinet.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Cocody',
                'category' => 'Santé et bien-être',
                'neighborhood' => 'Angré',
                'availability' => 'Sur rendez-vous, soirs de semaine',
                'budget' => null,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Coach sportif pour débutants',
                'description' => 'Je propose gratuitement deux séances par semaine au parc pour reprendre le sport en douceur : marche, gainage, échauffement.',
                'type' => 'OFFRE',
                'nature' => 'BENEVOLE',
                'commune' => 'Plateau',
                'category' => 'Sport et coaching',
                'neighborhood' => 'Centre-ville',
                'availability' => 'Mardi et jeudi, 6 h 30',
                'budget' => null,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Photographe pour baptêmes et anniversaires',
                'description' => 'Reportage photo en intérieur et extérieur, retouches incluses, galerie en ligne livrée sous une semaine.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Treichville',
                'category' => 'Photographie et vidéo',
                'neighborhood' => 'Marché',
                'availability' => 'Week-end',
                'budget' => null,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Dépannage batterie et démarreur',
                'description' => 'Je me déplace pour diagnostic, remplacement de batterie, démarreur et alternateur. Pièces à prix coûtant.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Port-Bouët',
                'category' => 'Mécanique et automobile',
                'neighborhood' => 'Vridi',
                'availability' => 'Tous les jours sauf dimanche',
                'budget' => null,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Cours d’anglais par conversation',
                'description' => 'Séances de conversation en anglais pour adultes et lycéens, en visio ou à domicile, tous niveaux.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Cocody',
                'category' => 'Langues et traduction',
                'neighborhood' => 'Riviera 4',
                'availability' => 'Mercredi et samedi',
                'budget' => 10000,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Courses et retrait d’argent pour une personne âgée',
                'description' => 'Un voisin bénévole propose de faire les courses et de retirer l’argent du mois pour une personne âgée du quartier, chaque lundi.',
                'type' => 'OFFRE',
                'nature' => 'BENEVOLE',
                'commune' => 'Abobo',
                'category' => 'Aide aux personnes âgées',
                'neighborhood' => 'Gbagba',
                'availability' => 'Le lundi matin',
                'budget' => null,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Rédaction de lettres et démarches administratives',
                'description' => 'Aide à la rédaction de courriers, réclamations et dossiers administratifs, avec relecture et remise en forme.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Plateau',
                'category' => 'Droit et démarches',
                'neighborhood' => 'Centre-ville',
                'availability' => 'Sur rendez-vous, en journée',
                'budget' => null,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Vente de plants et produits du jardin',
                'description' => 'Je vends des plants de tomate, manioc et piment, ainsi que des œufs frais, le samedi matin au marché.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Songon',
                'category' => 'Agriculture et élevage',
                'neighborhood' => 'Adiapodoumé',
                'availability' => 'Le samedi matin',
                'budget' => null,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Toilettage de chiens et chats',
                'description' => 'Bain, coupe de griffes et brossage à domicile ou en salon, pour chats et chiens de petite et moyenne taille.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Cocody',
                'category' => 'Animaux domestiques',
                'neighborhood' => 'Deux Plateaux',
                'availability' => 'Sur rendez-vous',
                'budget' => 5000,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Livraison de repas à moto',
                'description' => 'Je livre les repas et les petits colis de mon quartier à moto, du midi jusqu’à 22 h, y compris le dimanche.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Yopougon',
                'category' => 'Livraison et courses',
                'neighborhood' => 'Wassa',
                'availability' => 'Tous les jours, 11 h – 22 h',
                'budget' => null,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Animation son et lumière pour soirée',
                'description' => 'Sonorisation, micro, projecteur et enceintes pour anniversaires et soirées de quartier, installation comprise.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Marcory',
                'category' => 'Événements et animation',
                'neighborhood' => 'Remblais',
                'availability' => 'Week-end',
                'budget' => null,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Gardiennage de chantier la nuit',
                'description' => 'Chaîne de surveillance et rondes toutes les deux heures pour un chantier, du dimanche au jeudi.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Abobo',
                'category' => 'Sécurité et surveillance',
                'neighborhood' => 'PK18',
                'availability' => 'Nuit, du dimanche au jeudi',
                'budget' => 25000,
                'user_id' => $koffi->id,
            ],
            [
                'title' => 'Création de logo et de carte de visite',
                'description' => 'Création d’identité visuelle pour petit commerce : logo, carte de visite et bannière réseaux sociaux, trois pistes proposées.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Cocody',
                'category' => 'Communication et marketing',
                'neighborhood' => 'Angré',
                'availability' => 'Livraison sous 5 jours',
                'budget' => 15000,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Tenue de comptes d’une petite boutique',
                'description' => 'Je tiens les comptes d’une boutique ou d’un taxi-brousse : recettes, dépenses, inventaire et bilan mensuel.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Adjamé',
                'category' => 'Comptabilité et gestion',
                'neighborhood' => 'Gare',
                'availability' => 'Une fois par semaine',
                'budget' => 20000,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Cours de dessin pour enfants',
                'description' => 'Atelier de dessin et de peinture gratuit pour les enfants du quartier, mercredi après-midi, matériel fourni.',
                'type' => 'OFFRE',
                'nature' => 'BENEVOLE',
                'commune' => 'Treichville',
                'category' => 'Musique et arts',
                'neighborhood' => 'Marché',
                'availability' => 'Mercredi après-midi',
                'budget' => null,
                'user_id' => $awa->id,
            ],
            [
                'title' => 'Vente de tissus wax et accessoires',
                'description' => 'Wax, bazin et pagnes assortis en petite et grande largeur, avec couture possible chez la couturière du marché.',
                'type' => 'OFFRE',
                'nature' => 'REMUNEREE',
                'commune' => 'Treichville',
                'category' => 'Vente et petit commerce',
                'neighborhood' => 'Marché',
                'availability' => 'Du lundi au samedi',
                'budget' => null,
                'user_id' => $koffi->id,
            ],
        ];

        foreach ($listings as $index => $listing) {
            Listing::firstOrCreate(
                ['title' => $listing['title']],
                [
                    'user_id' => $listing['user_id'],
                    'category_id' => Category::where('name', $listing['category'])->value('id'),
                    'commune_id' => Commune::where('name', $listing['commune'])->value('id'),
                    'description' => $listing['description'],
                    'type' => $listing['type'],
                    'nature' => $listing['nature'],
                    'neighborhood' => $listing['neighborhood'],
                    'availability' => $listing['availability'],
                    'budget' => $listing['budget'],
                    'status' => 'PUBLIEE',
                    'created_at' => now()->subDays(count($listings) - $index),
                    'updated_at' => now()->subDays(count($listings) - $index),
                ],
            );
        }

        $this->seedConversation($koffi, $awa);
    }

    /**
     * Un fil de démonstration prêt à consulter en se connectant comme Koffi.
     *
     * @param  User  $koffi  auteur de l'annonce « Réparer un ventilateur de plafond »
     * @param  User  $awa  initiateur du fil
     */
    private function seedConversation(User $koffi, User $awa): void
    {
        $listing = Listing::where('title', 'Réparer un ventilateur de plafond')->first();

        if ($listing === null) {
            return;
        }

        $interaction = Interaction::firstOrCreate([
            'listing_id' => $listing->id,
            'initiator_id' => $awa->id,
        ]);

        $messages = [
            ['sender_id' => $awa->id, 'body' => 'Bonjour, votre annonce pour le ventilateur est-elle toujours d’actualité ?', 'created_at' => now()->subDay()],
            ['sender_id' => $koffi->id, 'body' => 'Bonjour Awa, oui toujours ! Je suis disponible en semaine après 16 h.', 'created_at' => now()->subDay()->addMinutes(45)],
        ];

        foreach ($messages as $message) {
            Message::firstOrCreate(
                ['interaction_id' => $interaction->id, 'body' => $message['body']],
                $message,
            );
        }
    }
}
