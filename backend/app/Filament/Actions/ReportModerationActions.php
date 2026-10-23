<?php

namespace App\Filament\Actions;

use App\Models\Report;
use App\Models\User;
use App\Support\Moderation\Decision;
use App\Support\Moderation\ReportModerator;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Notifications\Notification;
use Filament\Support\Icons\Heroicon;

/**
 * Actions de traitement d’un signalement, partagées entre la liste et la
 * page de vue : toute décision passe par `ReportModerator`, de sorte que
 * le journal `moderation_actions` ne présente aucun trou.
 */
final class ReportModerationActions
{
    public static function claim(): Action
    {
        return Action::make('prendre_en_charge')
            ->label('Prendre en charge')
            ->icon(Heroicon::OutlinedShieldCheck)
            ->color('warning')
            ->visible(fn (Report $record): bool => $record->status === 'NOUVEAU')
            ->requiresConfirmation()
            ->modalDescription('Le signalement passe en statut « En cours » et reste attribué à votre nom dans le journal.')
            ->action(function (Report $record): void {
                self::apply($record, Decision::PriseEnCharge, null);

                Notification::make()
                    ->title('Signalement pris en charge')
                    ->success()
                    ->send();
            });
    }

    public static function treat(): Action
    {
        return Action::make('traiter')
            ->label('Traiter')
            ->icon(Heroicon::OutlinedFlag)
            ->color('success')
            ->visible(fn (Report $record): bool => $record->status !== 'TRAITE')
            ->schema([
                Select::make('decision')
                    ->label('Décision')
                    ->options([
                        Decision::AnnonceMasquee->value => 'Masquer l’annonce signalée',
                        Decision::SansSuite->value => 'Classer sans suite (aucune infraction)',
                    ])
                    ->default(Decision::AnnonceMasquee->value)
                    ->required(),
                Textarea::make('justification')
                    ->label('Justification')
                    ->rows(3)
                    ->placeholder('Requise pour un masquage, facultative sinon.')
                    ->helperText('Consignée dans le journal de modération avec votre nom et l’horodatage.')
                    ->required(fn (callable $get): bool => $get('decision') === Decision::AnnonceMasquee->value),
            ])
            ->action(function (Report $record, array $data): void {
                self::apply(
                    $record,
                    Decision::from($data['decision']),
                    $data['justification'] ?? null,
                );

                Notification::make()
                    ->title('Signalement traité')
                    ->body(Decision::from($data['decision'])->label())
                    ->success()
                    ->send();
            });
    }

    public static function reject(): Action
    {
        return Action::make('rejeter')
            ->label('Rejeter le signalement')
            ->icon(Heroicon::OutlinedDocumentText)
            ->color('gray')
            ->visible(fn (Report $record): bool => $record->status !== 'REJETE' && $record->status !== 'TRAITE')
            ->schema([
                Textarea::make('justification')
                    ->label('Motif du rejet')
                    ->rows(3)
                    ->required()
                    ->placeholder('Pourquoi ce signalement ne peut pas prospérer.'),
            ])
            ->action(function (Report $record, array $data): void {
                self::apply($record, Decision::SignalementRejete, $data['justification']);

                Notification::make()
                    ->title('Signalement rejeté')
                    ->success()
                    ->send();
            });
    }

    private static function apply(Report $record, Decision $decision, ?string $justification): void
    {
        $moderator = auth()->user();

        if (! $moderator instanceof User) {
            abort(403);
        }

        ReportModerator::apply($record, $decision, $justification, $moderator);
    }
}
