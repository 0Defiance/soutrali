<?php

namespace App\Filament\Resources\Categories\Schemas;

use App\Models\Category;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class CategoryForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->label('Nom de la catégorie')
                    ->required()
                    ->maxLength(100)
                    ->unique(ignoreRecord: true),
                Textarea::make('description')
                    ->label('Description')
                    ->rows(3)
                    ->helperText('Affichée dans l’application pour guider le dépôt d’annonce.')
                    ->columnSpanFull(),
                Select::make('icon')
                    ->label('Icône du service')
                    ->options(Category::ICONS)
                    ->helperText('Icône affichée à côté du service dans l’application (listes, filtres et cartes).')
                    ->default('misc')
                    ->required()
                    ->native(false),
                Toggle::make('active')
                    ->label('Catégorie active')
                    ->helperText('Une catégorie inactive reste en base mais n’apparaît plus dans les formulaires.')
                    ->default(true)
                    ->required(),
            ]);
    }
}
