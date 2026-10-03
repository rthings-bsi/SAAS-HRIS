<?php

use App\Http\Controllers\Api\AttendanceController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    Route::get('attendance/today', [AttendanceController::class, 'today']);
    Route::post('attendance/clock-in', [AttendanceController::class, 'clockIn']);
    Route::post('attendance/clock-out', [AttendanceController::class, 'clockOut']);
    Route::get('attendance/history', [AttendanceController::class, 'history']);
    Route::get('attendance/recap', [AttendanceController::class, 'recap']);
});
