<?php

use App\Http\Controllers\Api\V1\PublicListingController;
use Illuminate\Support\Facades\Route;

Route::get('/v1/listings', [PublicListingController::class, 'index'])
    ->middleware('throttle:60,1');

Route::get('/v1/listings/{listing}', [PublicListingController::class, 'show'])
    ->middleware('throttle:60,1');