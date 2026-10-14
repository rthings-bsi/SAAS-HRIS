<?php

use App\Http\Controllers\Auth\AuthController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\CompanyProfileController;
use App\Http\Controllers\Organization\BranchController;
use App\Http\Controllers\Organization\DepartmentController;
use App\Http\Controllers\Organization\JobPositionController;
use Illuminate\Support\Facades\Route;

// Auth routes (Single Company Internal HRIS - Non-SaaS)
Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);
    });
});

// Organization routes
Route::middleware('auth:sanctum')->group(function () {
    // Company Profile
    Route::get('/company-profile', [CompanyProfileController::class, 'show']);
    Route::put('/company-profile', [CompanyProfileController::class, 'update']);

    // Branches
    Route::get('/branches', [BranchController::class, 'index']);
    Route::post('/branches', [BranchController::class, 'store']);
    Route::get('/branches/{id_branches}', [BranchController::class, 'show']);
    Route::put('/branches/{id_branches}', [BranchController::class, 'update']);
    Route::delete('/branches/{id_branches}', [BranchController::class, 'destroy']);

    // Departments
    Route::get('/departments', [DepartmentController::class, 'index']);
    Route::post('/departments', [DepartmentController::class, 'store']);
    Route::get('/departments/{id_departments}', [DepartmentController::class, 'show']);
    Route::put('/departments/{id_departments}', [DepartmentController::class, 'update']);
    Route::delete('/departments/{id_departments}', [DepartmentController::class, 'destroy']);

    // Job Positions
    Route::get('/job-positions', [JobPositionController::class, 'index']);
    Route::post('/job-positions', [JobPositionController::class, 'store']);
    Route::get('/job-positions/{id_job_positions}', [JobPositionController::class, 'show']);
    Route::put('/job-positions/{id_job_positions}', [JobPositionController::class, 'update']);
    Route::delete('/job-positions/{id_job_positions}', [JobPositionController::class, 'destroy']);

    // User & Role Management
    Route::get('/users', [UserController::class, 'index']);
    Route::put('/users/{id_users}/role', [UserController::class, 'updateRole']);
    Route::put('/users/{id_users}/status', [UserController::class, 'toggleStatus']);

    // Role Configuration & Custom Roles
    Route::get('/roles', [UserController::class, 'getRoles']);
    Route::post('/roles', [UserController::class, 'storeRole']);
    Route::put('/roles/{key}', [UserController::class, 'updateRoleConfig']);
    Route::delete('/roles/{key}', [UserController::class, 'destroyRole']);
    Route::post('/roles/reset', [UserController::class, 'resetRoles']);
});
