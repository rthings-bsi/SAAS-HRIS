<?php

use App\Http\Controllers\Api\PerformanceController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    Route::prefix('performance')->group(function () {
        // Kriteria Penilaian
        Route::get('criteria', [PerformanceController::class, 'criteria']);
        Route::post('criteria', [PerformanceController::class, 'storeCriterion']);
        Route::put('criteria/{id}', [PerformanceController::class, 'updateCriterion']);
        Route::post('criteria/reset-defaults', [PerformanceController::class, 'resetDefaultCriteria']);

        // Periode Penilaian (SPK SMART)
        Route::get('periods', [PerformanceController::class, 'periods']);
        Route::post('periods', [PerformanceController::class, 'storePeriod']);
        Route::get('periods/{id}', [PerformanceController::class, 'showPeriod']);
        Route::post('periods/{id}/sync-employees', [PerformanceController::class, 'syncEmployees']);
        Route::post('periods/{id}/scores', [PerformanceController::class, 'saveScores']);
        Route::post('periods/{id}/calculate', [PerformanceController::class, 'calculate']);
        Route::post('periods/{id}/finalize', [PerformanceController::class, 'finalize']);
        Route::get('periods/{id}/pdf', [PerformanceController::class, 'exportPdf']);
    });
});
