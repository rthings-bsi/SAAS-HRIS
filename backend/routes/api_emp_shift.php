<?php

use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\ShiftController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    // Master Shifts
    Route::get('shifts', [ShiftController::class, 'index']);
    Route::post('shifts', [ShiftController::class, 'store']);
    Route::get('shifts/{id_shifts}', [ShiftController::class, 'show']);
    Route::put('shifts/{id_shifts}', [ShiftController::class, 'update']);
    Route::delete('shifts/{id_shifts}', [ShiftController::class, 'destroy']);

    // Employee Shifts Assignment (must be before {id_employees} to avoid route conflicts)
    Route::post('employees/assign-shift', [ShiftController::class, 'assignShift']);

    // Master Employees
    Route::get('employees', [EmployeeController::class, 'index']);
    Route::post('employees', [EmployeeController::class, 'store']);
    Route::get('employees/{id_employees}', [EmployeeController::class, 'show']);
    Route::put('employees/{id_employees}', [EmployeeController::class, 'update']);
    Route::delete('employees/{id_employees}', [EmployeeController::class, 'destroy']);
});
