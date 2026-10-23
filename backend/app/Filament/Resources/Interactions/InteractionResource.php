<?php

namespace App\Filament\Resources\Interactions;

use App\Filament\Resources\Interactions\Pages\ListInteractions;
use App\Filament\Resources\Interactions\Pages\ViewInteraction;
use App\Filament\Resources\Interactions\Schemas\InteractionInfolist;
use App\Filament\Resources\Interactions\Tables\InteractionsTable;
use App\Models\Interaction;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use UnitEnum;

/**
 * Fils de discussion (D-05) : consultation seule côté back-office, pour
 * instruire un litige. Les fils et les messages vivent dans
 * l’application ; rien ne se crée, modifie ni ne supprime ici.
 */
class InteractionResource extends Resource
{
    protected static ?string $model = Interaction::class;

    protected static ?string $modelLabel = 'conversation';

    protected static ?string $pluralModelLabel = 'conversations';

    protected static ?string $navigationLabel = 'Conversations';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedChatBubbleLeftRight;

    protected static string|UnitEnum|null $navigationGroup = 'Modération';

    protected static ?int $navigationSort = 2;

    public static function infolist(Schema $schema): Schema
    {
        return InteractionInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return InteractionsTable::configure($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListInteractions::route('/'),
            'view' => ViewInteraction::route('/{record}'),
        ];
    }
}
