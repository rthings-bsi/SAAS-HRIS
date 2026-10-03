<?php

use App\Http\Controllers\SuperAdmin\CompanyController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->prefix('superadmin')->group(function () {
    Route::get('/stats', [CompanyController::class, 'stats']);
    Route::get('/companies', [CompanyController::class, 'index']);
    Route::get('/companies/{id_companies}', [CompanyController::class, 'show']);
    Route::put('/companies/{id_companies}', [CompanyController::class, 'update']);
    Route::delete('/companies/{id_companies}', [CompanyController::class, 'destroy']);
});
