<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Overtime\ApplyOvertimeRequest;
use App\Http\Requests\Overtime\OvertimeApprovalActionRequest;
use App\Http\Requests\Overtime\UpdateOvertimeRequest;
use App\Models\Attendance;
use App\Models\OvertimeRequest;
use App\Services\Overtime\OvertimeService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class OvertimeController extends Controller
{
    public function __construct(
        protected OvertimeService $overtimeService
    ) {}

    /**
     * Melampirkan jam masuk/keluar aktual pada tanggal lembur secara batch (tanpa N+1).
     */
    private function attachActualAttendance(iterable $items, int $companyId): void
    {
        $rows = collect($items);
        if ($rows->isEmpty()) {
            return;
        }

        $employeeIds = $rows->pluck('id_employees')->filter()->unique()->values();
        $dates = $rows->map(function ($row) {
            if ($row->date instanceof Carbon) {
                return $row->date->format('Y-m-d');
            }
            $str = (string) $row->date;

            return strlen($str) >= 10 ? substr($str, 0, 10) : $str;
        })->filter()->unique()->values();

        if ($employeeIds->isEmpty() || $dates->isEmpty()) {
            return;
        }

        $attendances = Attendance::where('id_companies', $companyId)
            ->whereIn('id_employees', $employeeIds)
            ->whereIn('date', $dates)
            ->get()
            ->keyBy(function ($att) {
                $d = $att->date instanceof Carbon
                    ? $att->date->format('Y-m-d')
                    : substr((string) $att->date, 0, 10);

                return $att->id_employees . '|' . $d;
            });

        foreach ($rows as $row) {
            $d = $row->date instanceof Carbon
                ? $row->date->format('Y-m-d')
                : substr((string) $row->date, 0, 10);
            $att = $attendances->get($row->id_employees . '|' . $d);
            $row->setAttribute('actual_clock_in', $att?->clock_in_time);
            $row->setAttribute('actual_clock_out', $att?->clock_out_time);
        }
    }

    /**
     * Mengambil daftar riwayat lembur milik karyawan login.
     */
    public function myRequests(Request $request): JsonResponse
    {
        $user = $request->user();
        $employee = $user?->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 404);
        }

        $query = OvertimeRequest::where('id_employees', $employee->id_employees)
            ->with(['employee.user', 'employee.shift', 'approver']);

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('month')) {
            $query->where('date', 'like', $request->input('month') . '%');
        }

        $perPage = (int) $request->input('per_page', 15);
        $requests = $query->orderByDesc('date')->orderByDesc('id_overtime_requests')->paginate($perPage);
        $this->attachActualAttendance($requests->getCollection(), (int) $employee->id_companies);

        return $this->successResponse($requests, 'Riwayat pengajuan lembur berhasil diambil.');
    }

    /**
     * Mengajukan permohonan lembur baru oleh karyawan.
     */
    public function applyOvertime(ApplyOvertimeRequest $request): JsonResponse
    {
        $user = $request->user();
        $employee = $user?->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 404);
        }

        try {
            $validated = $request->validated();
            $attachment = $request->file('attachment');

            if (isset($validated['entries'])) {
                $created = $this->overtimeService->applyOvertimeBatch(
                    $employee,
                    $validated['entries'],
                    $validated['reason'],
                    $validated['overtime_type'] ?? null,
                    $validated['reason_category'] ?? null,
                    $attachment
                );
                $count = count($created);

                return $this->successResponse(
                    $created,
                    "{$count} pengajuan lembur berhasil dikirim.",
                    201
                );
            }

            $overtime = $this->overtimeService->applyOvertime(
                $employee,
                $validated,
                $attachment
            );

            return $this->successResponse(
                $overtime,
                'Pengajuan lembur berhasil dikirim.',
                201
            );
        } catch (ValidationException $e) {
            return $this->errorResponse($e->getMessage(), $e->errors(), 422);
        }
    }

    /**
     * Memperbarui / merevisi permohonan lembur oleh karyawan.
     */
    public function updateRequest(UpdateOvertimeRequest $request, int|string $id): JsonResponse
    {
        $user = $request->user();
        $employee = $user?->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 404);
        }

        $overtime = OvertimeRequest::where('id_companies', $employee->id_companies)
            ->find($id);

        if (! $overtime) {
            return $this->errorResponse('Pengajuan lembur tidak ditemukan.', null, 404);
        }

        try {
            $updated = $this->overtimeService->updateOvertime(
                $overtime,
                $employee,
                $request->validated(),
                $request->file('attachment')
            );

            return $this->successResponse(
                $updated,
                'Pengajuan lembur berhasil diperbarui.'
            );
        } catch (ValidationException $e) {
            return $this->errorResponse($e->getMessage(), $e->errors(), 422);
        }
    }

    /**
     * Membatalkan permohonan lembur oleh karyawan.
     */
    public function cancelRequest(Request $request, int|string $id): JsonResponse
    {
        $user = $request->user();
        $employee = $user?->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 404);
        }

        $overtime = OvertimeRequest::where('id_companies', $employee->id_companies)
            ->find($id);

        if (! $overtime) {
            return $this->errorResponse('Pengajuan lembur tidak ditemukan.', null, 404);
        }

        try {
            $reason = $request->input('reason');
            $cancelled = $this->overtimeService->cancelOvertime(
                $overtime,
                $employee,
                $reason
            );

            return $this->successResponse(
                $cancelled,
                'Pengajuan lembur berhasil dibatalkan.'
            );
        } catch (ValidationException $e) {
            return $this->errorResponse($e->getMessage(), $e->errors(), 422);
        }
    }

    /**
     * Mengambil daftar seluruh pengajuan lembur untuk persetujuan (Atasan / HR).
     */
    public function approvals(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! in_array($user?->role, ['owner', 'hr', 'manager', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki izin melihat daftar persetujuan lembur.', null, 403);
        }

        $query = OvertimeRequest::where('id_companies', $user->id_companies)
            ->with(['employee.user', 'employee.shift', 'approver']);

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('date')) {
            $query->where('date', $request->input('date'));
        }

        $perPage = (int) $request->input('per_page', 15);
        $approvals = $query->orderByDesc('id_overtime_requests')->paginate($perPage);
        $this->attachActualAttendance($approvals->getCollection(), (int) $user->id_companies);

        return $this->successResponse($approvals, 'Daftar pengajuan lembur untuk persetujuan berhasil diambil.');
    }

    /**
     * Memproses aksi persetujuan atau penolakan pengajuan lembur.
     */
    public function takeApprovalAction(OvertimeApprovalActionRequest $request, int|string $id): JsonResponse
    {
        $user = $request->user();

        if (! in_array($user?->role, ['owner', 'hr', 'manager', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki izin memproses persetujuan lembur.', null, 403);
        }

        $overtime = OvertimeRequest::where('id_companies', $user->id_companies)
            ->find($id);

        if (! $overtime) {
            return $this->errorResponse('Pengajuan lembur tidak ditemukan.', null, 404);
        }

        try {
            $updated = $this->overtimeService->processApproval(
                $overtime,
                $user,
                $request->input('action'),
                $request->input('notes')
            );

            return $this->successResponse($updated, 'Status pengajuan lembur berhasil diperbarui.');
        } catch (ValidationException $e) {
            return $this->errorResponse($e->getMessage(), $e->errors(), 422);
        }
    }
}
