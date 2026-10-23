<?php

namespace App\Filament\Resources\Listings;

use App\Filament\Resources\Listings\Pages\EditListing;
use App\Filament\Resources\Listings\Pages\ListListings;
use App\Filament\Resources\Listings\Schemas\ListingForm;
use App\Filament\Resources\Listings\Tables\ListingsTable;
use App\Models\Listing;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use UnitEnum;

/**
 * Annonces côté back-office : consultation, édition limitée et
 * modération (masquage / republiage tracés). La création se fait par
 * l’API de l’application, la suppression est interdite (masquage à la
 * place, pour conserver la trace).
 */
class ListingResource extends Resource
{
    protected static ?string $model = Listing::class;

    protected static ?string $modelLabel = 'annonce';

    protected static ?string $pluralModelLabel = 'annonces';

    protected static ?string $navigationLabel = 'Annonces';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedNewspaper;

    protected static string|UnitEnum|null $navigationGroup = 'Contenus';

    protected static ?int $navigationSort = 1;

    public static function form(Schema $schema): Schema
    {
        return ListingForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return ListingsTable::configure($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListListings::route('/'),
            'edit' => EditListing::route('/{record}/edit'),
        ];
    }
}
