<?php

namespace App\Filament\Resources\Communes\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class CommuneForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->label('Nom de la commune')
                    ->required()
                    ->maxLength(80)
                    ->unique(ignoreRecord: true),
                Toggle::make('active')
                    ->label('Commune active')
                    ->helperText('Une commune inactive reste en base mais n’apparaît plus dans les formulaires.')
                    ->default(true)
                    ->required(),
            ]);
    }
}
