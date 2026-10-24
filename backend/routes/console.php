<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Publication programmée : normalise les statuts chaque minute
// (`php artisan schedule:work` en local, cron en production).
Schedule::command('soutrali:publish-due')->everyMinute();
