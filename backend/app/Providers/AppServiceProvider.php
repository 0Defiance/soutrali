<?php

namespace App\Providers;

use App\Models\Category;
use App\Models\Commune;
use App\Models\Interaction;
use App\Models\Listing;
use App\Models\Message;
use App\Models\ModerationAction;
use App\Models\Report;
use App\Models\User;
use App\Policies\CategoryPolicy;
use App\Policies\CommunePolicy;
use App\Policies\InteractionPolicy;
use App\Policies\ListingPolicy;
use App\Policies\MessagePolicy;
use App\Policies\ModerationActionPolicy;
use App\Policies\ReportPolicy;
use App\Policies\UserPolicy;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Policies du back-office Filament : enregistrement explicite pour
     * que le modèle de privilèges (D-04/D-06) ne dépende d’aucune
     * convention de découverte — le mode strict du panneau s’y appuie.
     *
     * @var array<class-string, class-string>
     */
    private const POLICIES = [
        User::class => UserPolicy::class,
        Listing::class => ListingPolicy::class,
        Report::class => ReportPolicy::class,
        Interaction::class => InteractionPolicy::class,
        Message::class => MessagePolicy::class,
        ModerationAction::class => ModerationActionPolicy::class,
        Category::class => CategoryPolicy::class,
        Commune::class => CommunePolicy::class,
    ];

    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        foreach (self::POLICIES as $model => $policy) {
            Gate::policy($model, $policy);
        }
    }
}
