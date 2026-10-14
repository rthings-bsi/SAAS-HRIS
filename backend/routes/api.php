<?php

use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    require __DIR__ . '/api_auth_org.php';
    require __DIR__ . '/api_emp_shift.php';
    require __DIR__ . '/api_attendance.php';
    require __DIR__ . '/api_leave.php';
    require __DIR__ . '/api_overtime.php';
    require __DIR__ . '/api_payroll.php';
    require __DIR__ . '/api_performance.php';
    require __DIR__ . '/api_notification.php';
});
