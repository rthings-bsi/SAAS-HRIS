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

    private function normalizeIsoDate(mixed $value): string
    {
        if ($value instanceof Carbon) {
            return $value->format('Y-m-d');
        }
        $str = (string) $value;

        return strlen($str) >= 10 ? substr($str, 0, 10) : $str;
    }

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
        $dates = collect();

        foreach ($rows as $row) {
            $dates->push($this->normalizeIsoDate($row->date));
            if ($row->relationLoaded('items') && $row->items->isNotEmpty()) {
                foreach ($row->items as $child) {
                    $dates->push($this->normalizeIsoDate($child->date));
                }
            }
        }

        $dates = $dates->filter()->unique()->values();

        if ($employeeIds->isEmpty() || $dates->isEmpty()) {
            return;
        }

        $attendances = Attendance::where('id_companies', $companyId)
            ->whereIn('id_employees', $employeeIds)
            ->whereIn('date', $dates)
            ->get()
            ->keyBy(function ($att) {
                return $att->id_employees . '|' . $this->normalizeIsoDate($att->date);
            });

        foreach ($rows as $row) {
            $d = $this->normalizeIsoDate($row->date);
            $att = $attendances->get($row->id_employees . '|' . $d);
            $row->setAttribute('actual_clock_in', $att?->clock_in_time);
            $row->setAttribute('actual_clock_out', $att?->clock_out_time);

            if ($row->relationLoaded('items') && $row->items->isNotEmpty()) {
                foreach ($row->items as $child) {
                    $cd = $this->normalizeIsoDate($child->date);
                    $childAtt = $attendances->get($row->id_employees . '|' . $cd);
                    $child->setAttribute('actual_clock_in', $childAtt?->clock_in_time);
                    $child->setAttribute('actual_clock_out', $childAtt?->clock_out_time);
                }
            }
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
            ->with(['items', 'employee.user', 'employee.shift', 'approver']);

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('month')) {
            $monthPrefix = $request->input('month') . '%';
            $query->where(function ($q) use ($monthPrefix) {
                $q->where('date', 'like', $monthPrefix)
                    ->orWhereHas('items', function ($iq) use ($monthPrefix) {
                        $iq->where('date', 'like', $monthPrefix);
                    });
            });
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
                $overtime = $this->overtimeService->applyOvertimeBatch(
                    $employee,
                    $validated['entries'],
                    $validated['reason'],
                    $validated['overtime_type'] ?? null,
                    $validated['reason_category'] ?? null,
                    $attachment
                );
                $itemCount = $overtime->items->count();
                $message = $itemCount > 1
                    ? "Pengajuan lembur ({$itemCount} sesi) berhasil dikirim."
                    : 'Pengajuan lembur berhasil dikirim.';

                $this->attachActualAttendance([$overtime], (int) $employee->id_companies);

                return $this->successResponse(
                    $overtime,
                    $message,
                    201
                );
            }

            $overtime = $this->overtimeService->applyOvertime(
                $employee,
                $validated,
                $attachment
            );
            $this->attachActualAttendance([$overtime], (int) $employee->id_companies);

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
            $this->attachActualAttendance([$updated], (int) $employee->id_companies);

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
            $this->attachActualAttendance([$cancelled], (int) $employee->id_companies);

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
            ->with(['items', 'employee.user', 'employee.shift', 'approver']);

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('date')) {
            $targetDate = $request->input('date');
            $query->where(function ($q) use ($targetDate) {
                $q->whereHas('items', function ($iq) use ($targetDate) {
                    $iq->where('date', $targetDate);
                })->orWhere(function ($legacy) use ($targetDate) {
                    $legacy->doesntHave('items')->where('date', $targetDate);
                });
            });
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
            $this->attachActualAttendance([$updated], (int) $user->id_companies);

            return $this->successResponse($updated, 'Status pengajuan lembur berhasil diperbarui.');
        } catch (ValidationException $e) {
            return $this->errorResponse($e->getMessage(), $e->errors(), 422);
        }
    }
}
