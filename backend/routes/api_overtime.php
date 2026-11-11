<?php

use App\Http\Controllers\Api\OvertimeController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    Route::prefix('overtime')->group(function () {
        Route::get('my-requests', [OvertimeController::class, 'myRequests']);
        Route::post('request', [OvertimeController::class, 'applyOvertime']);
        Route::put('requests/{id}', [OvertimeController::class, 'updateRequest']);
        Route::post('requests/{id}/update', [OvertimeController::class, 'updateRequest']);
        Route::post('requests/{id}/cancel', [OvertimeController::class, 'cancelRequest']);
        Route::delete('requests/{id}', [OvertimeController::class, 'cancelRequest']);
        Route::get('approvals', [OvertimeController::class, 'approvals']);
        Route::post('approvals/{id}/action', [OvertimeController::class, 'takeApprovalAction']);
    });
});
