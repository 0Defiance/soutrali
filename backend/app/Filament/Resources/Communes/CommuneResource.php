<?php

namespace App\Filament\Resources\Communes;

use App\Filament\Resources\Communes\Pages\CreateCommune;
use App\Filament\Resources\Communes\Pages\EditCommune;
use App\Filament\Resources\Communes\Pages\ListCommunes;
use App\Filament\Resources\Communes\Schemas\CommuneForm;
use App\Filament\Resources\Communes\Tables\CommunesTable;
use App\Models\Commune;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use UnitEnum;

class CommuneResource extends Resource
{
    protected static ?string $model = Commune::class;

    protected static ?string $modelLabel = 'commune';

    protected static ?string $pluralModelLabel = 'communes';

    protected static ?string $navigationLabel = 'Communes';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedMapPin;

    protected static string|UnitEnum|null $navigationGroup = 'Contenus';

    protected static ?int $navigationSort = 3;

    public static function form(Schema $schema): Schema
    {
        return CommuneForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return CommunesTable::configure($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListCommunes::route('/'),
            'create' => CreateCommune::route('/create'),
            'edit' => EditCommune::route('/{record}/edit'),
        ];
    }
}
