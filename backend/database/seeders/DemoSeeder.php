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
