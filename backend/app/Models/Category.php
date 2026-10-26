<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Category extends Model
{
    /**
     * Clés d'icônes acceptées (clé d'icône => libellé affiché dans le
     * back-office). Les mêmes clés sont traduites en icônes Flutter par
     * `app/lib/src/features/discover/category_icons.dart` : ajouter une
     * clé ici suppose de l'ajouter des deux côtés.
     *
     * @var array<string, string>
     */
    public const ICONS = [
        'repair' => 'Outil et dépannage',
        'house' => 'Maison et entretien',
        'beauty' => 'Ciseaux et mise en beauté',
        'education' => 'Casquette d’étudiant',
        'digital' => 'Écrans et numérique',
        'moving' => 'Camion de déménagement',
        'help' => 'Mains solidaires',
        'misc' => 'Divers',
        'plumbing' => 'Clé et robinet',
        'electricity' => 'Éclairage électrique',
        'carpentry' => 'Scie et bois',
        'painting' => 'Rouleau de peinture',
        'masonry' => 'Casque de chantier',
        'gardening' => 'Feuille et jardinage',
        'childcare' => 'Enfant et doudou',
        'elderly' => 'Accompagnement des aînés',
        'catering' => 'Assiette et cuisine',
        'health' => 'Bien-être',
        'sport' => 'Haltère et sport',
        'photo' => 'Appareil photo',
        'events' => 'Fête et animation',
        'auto' => 'Voiture et mécanique',
        'delivery' => 'Livraison à moto',
        'business' => 'Calcul et gestion',
        'legal' => 'Marteau de justice',
        'languages' => 'Traduction',
        'security' => 'Bouclier de sécurité',
        'pets' => 'Animaux domestiques',
        'arts' => 'Notes de musique',
        'marketing' => 'Communication',
        'commerce' => 'Devanture de commerce',
        'agriculture' => 'Agriculture',
    ];

    protected $fillable = ['name', 'description', 'icon', 'active'];

    protected function casts(): array
    {
        return ['active' => 'boolean'];
    }

    public function listings(): HasMany
    {
        return $this->hasMany(Listing::class);
    }
}
