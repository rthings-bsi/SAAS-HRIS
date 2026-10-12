<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\AttendanceException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Attendance\ClockInRequest;
use App\Http\Requests\Attendance\ClockOutRequest;
use App\Services\Attendance\AttendanceService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function __construct(
        protected AttendanceService $attendanceService
    ) {}

    public function today(Request $request): JsonResponse
    {
        /** @var \App\Models\User|null $user */
        $user = $request->user();
        $employee = $user?->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 404);
        }

        $date = $request->input('date', Carbon::today()->toDateString());
        $data = $this->attendanceService->getTodayAttendance($employee, $date);

        return $this->successResponse($data, 'Data presensi hari ini berhasil diambil.');
    }

    public function clockIn(ClockInRequest $request): JsonResponse
    {
        /** @var \App\Models\User|null $user */
        $user = $request->user();
        $employee = $user?->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 422);
        }

        try {
            $attendance = $this->attendanceService->clockIn(
                $employee,
                $request->validated(),
                $request->file('photo')
            );

            return $this->successResponse($attendance, 'Clock-in berhasil.', 201);
        } catch (AttendanceException $e) {
            return $this->errorResponse($e->getMessage(), null, $e->getCode() ?: 422);
        }
    }

    public function clockOut(ClockOutRequest $request): JsonResponse
    {
        /** @var \App\Models\User|null $user */
        $user = $request->user();
        $employee = $user?->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 422);
        }

        try {
            $attendance = $this->attendanceService->clockOut(
                $employee,
                $request->validated(),
                $request->file('photo')
            );

            return $this->successResponse($attendance, 'Clock-out berhasil.');
        } catch (AttendanceException $e) {
            return $this->errorResponse($e->getMessage(), null, $e->getCode() ?: 422);
        }
    }

    public function history(Request $request): JsonResponse
    {
        /** @var \App\Models\User|null $user */
        $user = $request->user();
        $employee = $user?->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 404);
        }

        $perPage = (int) $request->input('per_page', 15);
        $history = $this->attendanceService->getHistory($employee, $request->all(), $perPage);

        return $this->successResponse($history, 'Riwayat presensi berhasil diambil.');
    }

    public function recap(Request $request): JsonResponse
    {
        /** @var \App\Models\User|null $user */
        $user = $request->user();

        if (! in_array($user?->role, ['owner', 'hr', 'manager', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki izin melihat rekap presensi.', null, 403);
        }

        $companyId = $user->id_companies ?? (int) $request->input('id_companies', 1) ?: 1;

        $date = $request->input('date');
        $month = $request->input('month');

        $recap = $this->attendanceService->getRecapData($companyId, $date, $month);

        return $this->successResponse($recap, 'Rekap presensi berhasil diambil.');
    }
}
