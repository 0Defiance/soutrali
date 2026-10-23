<?php

namespace App\Filament\Widgets;

use App\Models\Interaction;
use App\Models\Listing;
use App\Models\Message;
use App\Models\Report;
use App\Models\User;
use Filament\Support\Icons\Heroicon;
use Filament\Widgets\StatsOverviewWidget as BaseStatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

/**
 * Vue d’ensemble du pilote : comptes, contenus, file des signalements
 * et activité de messagerie. Les chiffres sont comptés sur demande
 * (aucune donnée mise en cache — volumes encore faibles).
 */
class StatsOverviewWidget extends BaseStatsOverviewWidget
{
    protected static ?int $sort = 1;

    /**
     * @return array<int, Stat>
     */
    protected function getStats(): array
    {
        $pendingReports = Report::whereIn('status', ['NOUVEAU', 'EN_COURS'])->count();

        return [
            Stat::make('Comptes', User::count())
                ->description(sprintf(
                    '%d actifs · %d suspendus',
                    User::where('status', 'ACTIF')->count(),
                    User::where('status', 'SUSPENDU')->count(),
                ))
                ->descriptionIcon(Heroicon::OutlinedUserGroup)
                ->color('info'),
            Stat::make('Annonces publiées', Listing::where('status', 'PUBLIEE')->count())
                ->description(sprintf(
                    '%d masquées · %d clôturées',
                    Listing::where('status', 'MASQUEE')->count(),
                    Listing::where('status', 'CLOTUREE')->count(),
                ))
                ->descriptionIcon(Heroicon::OutlinedNewspaper)
                ->color('success'),
            Stat::make('Signalements en attente', $pendingReports)
                ->description(Report::count().' signalements déposés au total')
                ->descriptionIcon(Heroicon::OutlinedFlag)
                ->color($pendingReports > 0 ? 'danger' : 'success'),
            Stat::make('Conversations', Interaction::count())
                ->description(Message::count().' messages échangés')
                ->descriptionIcon(Heroicon::OutlinedChatBubbleLeftRight)
                ->color('primary'),
        ];
    }
}
