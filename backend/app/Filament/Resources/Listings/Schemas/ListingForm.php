<?php

namespace App\Filament\Resources\Listings\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class ListingForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('title')
                    ->label('Titre')
                    ->required()
                    ->maxLength(140),
                Textarea::make('description')
                    ->label('Description')
                    ->rows(6)
                    ->required()
                    ->columnSpanFull(),
                Select::make('type')
                    ->label('Type')
                    ->options([
                        'DEMANDE' => 'Demande',
                        'OFFRE' => 'Offre',
                    ])
                    ->required(),
                Select::make('nature')
                    ->label('Nature')
                    ->options([
                        'BENEVOLE' => 'Bénévole',
                        'REMUNEREE' => 'Rémunérée',
                    ])
                    ->required(),
                Select::make('category_id')
                    ->label('Catégorie')
                    ->relationship('category', 'name')
                    ->searchable()
                    ->preload()
                    ->required(),
                Select::make('commune_id')
                    ->label('Commune')
                    ->relationship('commune', 'name')
                    ->searchable()
                    ->preload()
                    ->required(),
                TextInput::make('neighborhood')
                    ->label('Quartier')
                    ->maxLength(100),
                TextInput::make('availability')
                    ->label('Disponibilité')
                    ->maxLength(160),
                TextInput::make('budget')
                    ->label('Budget (FCFA)')
                    ->numeric(),
                Select::make('status')
                    ->label('Statut')
                    ->options([
                        'BROUILLON' => 'Brouillon',
                        'PUBLIEE' => 'Publiée',
                        'MASQUEE' => 'Masquée',
                        'CLOTUREE' => 'Clôturée',
                    ])
                    ->required(),
                Select::make('closure_outcome')
                    ->label('Issue de clôture')
                    ->options([
                        'BESOIN_SATISFAIT' => 'Besoin satisfait',
                        'SOLUTION_TROUVEE' => 'Solution trouvée',
                    ])
                    ->nullable()
                    ->visible(fn (callable $get): bool => $get('status') === 'CLOTUREE'),
                Select::make('user_id')
                    ->label('Auteur')
                    ->relationship('author', 'display_name')
                    ->searchable()
                    ->preload()
                    ->required(),
            ])
            ->columns(2);
    }
}
