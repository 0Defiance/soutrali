<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ConversationController;
use App\Http\Controllers\Api\V1\MyListingController;
use App\Http\Controllers\Api\V1\PublicListingController;
use App\Http\Controllers\Api\V1\PublicReferenceController;
use App\Http\Controllers\Api\V1\ReportController;
use Illuminate\Support\Facades\Route;

// -------------------------------------------------------------------------
// Public
// -------------------------------------------------------------------------

Route::get('/v1/listings', [PublicListingController::class, 'index'])
    ->middleware('throttle:60,1');

Route::get('/v1/listings/{listing}', [PublicListingController::class, 'show'])
    ->middleware('throttle:60,1');

Route::get('/v1/categories', [PublicReferenceController::class, 'categories'])
    ->middleware('throttle:60,1');

Route::get('/v1/communes', [PublicReferenceController::class, 'communes'])
    ->middleware('throttle:60,1');

Route::post('/v1/register', [AuthController::class, 'register'])
    ->middleware('throttle:10,1');

Route::post('/v1/login', [AuthController::class, 'login'])
    ->middleware('throttle:10,1');

Route::get('/v1/csrf-token', [AuthController::class, 'csrfToken']);

// -------------------------------------------------------------------------
// Authentifié (session web Sanctum — D-04 validée le 22 oct. 2026)
// -------------------------------------------------------------------------

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/v1/me', [AuthController::class, 'me']);
    Route::post('/v1/logout', [AuthController::class, 'logout']);

    Route::post('/v1/listings', [MyListingController::class, 'store']);
    Route::get('/v1/me/listings', [MyListingController::class, 'index']);
    Route::patch('/v1/listings/{listing}', [MyListingController::class, 'update']);
    Route::post('/v1/listings/{listing}/close', [MyListingController::class, 'close']);

    Route::post('/v1/listings/{listing}/conversations', [ConversationController::class, 'start']);
    Route::get('/v1/conversations', [ConversationController::class, 'index']);
    Route::get('/v1/conversations/{interaction}', [ConversationController::class, 'show']);
    Route::post('/v1/conversations/{interaction}/messages', [ConversationController::class, 'sendMessage']);

    Route::post('/v1/listings/{listing}/reports', [ReportController::class, 'store']);
    Route::get('/v1/me/reports', [ReportController::class, 'myReports']);
});
