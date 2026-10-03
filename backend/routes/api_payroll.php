<?php

use App\Http\Controllers\Api\PayrollController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    Route::prefix('payroll')->group(function () {
        // Periode & Penggajian (HR, Owner, Superadmin)
        Route::get('periods', [PayrollController::class, 'periods']);
        Route::post('periods', [PayrollController::class, 'storePeriod']);
        Route::get('periods/{id}', [PayrollController::class, 'showPeriod']);
        Route::post('periods/{id}/calculate', [PayrollController::class, 'calculate']);
        Route::get('periods/{id}/slips', [PayrollController::class, 'slips']);
        Route::post('periods/{id}/finalize', [PayrollController::class, 'finalize']);

        // Download slip oleh HR/Owner
        Route::get('slips/{id}/download', [PayrollController::class, 'downloadSlip']);

        // Slip Gaji Karyawan (Mobile App)
        Route::get('my-slips', [PayrollController::class, 'mySlips']);
        Route::get('my-slips/{id}/download', [PayrollController::class, 'downloadMySlip']);
    });
});
