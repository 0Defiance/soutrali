<?php

use App\Http\Controllers\Api\V1\PublicListingController;
use App\Http\Controllers\Api\V1\PublicReferenceController;
use Illuminate\Support\Facades\Route;

Route::get('/v1/listings', [PublicListingController::class, 'index'])
    ->middleware('throttle:60,1');

Route::get('/v1/listings/{listing}', [PublicListingController::class, 'show'])
    ->middleware('throttle:60,1');

Route::get('/v1/categories', [PublicReferenceController::class, 'categories'])
    ->middleware('throttle:60,1');

Route::get('/v1/communes', [PublicReferenceController::class, 'communes'])
    ->middleware('throttle:60,1');
