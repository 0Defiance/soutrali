<?php

namespace App\Filament\Resources\ModerationActions;

use App\Filament\Resources\ModerationActions\Pages\ListModerationActions;
use App\Filament\Resources\ModerationActions\Tables\ModerationActionsTable;
use App\Models\ModerationAction;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use UnitEnum;

/**
 * Journal de modération : liste consultative uniquement (index), aucune
 * création, modification ni suppression possible — voir
 * `ModerationActionPolicy`.
 */
class ModerationActionResource extends Resource
{
    protected static ?string $model = ModerationAction::class;

    protected static ?string $modelLabel = 'action de modération';

    protected static ?string $pluralModelLabel = 'actions de modération';

    protected static ?string $navigationLabel = 'Journal de modération';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedClipboardDocumentList;

    protected static string|UnitEnum|null $navigationGroup = 'Modération';

    protected static ?int $navigationSort = 3;

    protected static bool $shouldRegisterNavigation = true;

    public static function table(Table $table): Table
    {
        return ModerationActionsTable::configure($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListModerationActions::route('/'),
        ];
    }
}
