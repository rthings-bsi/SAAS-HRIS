<?php

use App\Http\Controllers\Api\LeaveController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    // Leave endpoints (/api/v1/leave/...)
    Route::prefix('leave')->group(function () {
        Route::get('types', [LeaveController::class, 'types']);
        Route::post('types', [LeaveController::class, 'storeType']);
        Route::get('balance', [LeaveController::class, 'balance']);
        Route::get('my-requests', [LeaveController::class, 'myRequests']);
        Route::post('request', [LeaveController::class, 'applyLeave']);
        Route::get('approvals', [LeaveController::class, 'approvals']);
        Route::post('approvals/{id}/action', [LeaveController::class, 'takeApprovalAction']);
    });

    // Also support plural (/api/v1/leaves/...) as per API_SPEC.md
    Route::prefix('leaves')->group(function () {
        Route::get('types', [LeaveController::class, 'types']);
        Route::post('types', [LeaveController::class, 'storeType']);
        Route::get('balance', [LeaveController::class, 'balance']);
        Route::get('my-requests', [LeaveController::class, 'myRequests']);
        Route::post('request', [LeaveController::class, 'applyLeave']);
        Route::get('approvals', [LeaveController::class, 'approvals']);
        Route::post('approvals/{id}/action', [LeaveController::class, 'takeApprovalAction']);
        Route::post('{id}/action', [LeaveController::class, 'takeApprovalAction']);
    });
});
