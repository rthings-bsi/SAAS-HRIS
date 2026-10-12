<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Overtime\ApplyOvertimeRequest;
use App\Http\Requests\Overtime\OvertimeApprovalActionRequest;
use App\Models\OvertimeRequest;
use App\Services\Overtime\OvertimeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class OvertimeController extends Controller
{
    public function __construct(
        protected OvertimeService $overtimeService
    ) {}

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
            ->with(['approver']);

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('month')) {
            $query->where('date', 'like', $request->input('month') . '%');
        }

        $perPage = (int) $request->input('per_page', 15);
        $requests = $query->orderByDesc('date')->orderByDesc('id_overtime_requests')->paginate($perPage);

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
            $overtime = $this->overtimeService->applyOvertime(
                $employee,
                $request->validated()
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
     * Mengambil daftar seluruh pengajuan lembur untuk persetujuan (Atasan / HR).
     */
    public function approvals(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! in_array($user?->role, ['owner', 'hr', 'manager', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki izin melihat daftar persetujuan lembur.', null, 403);
        }

        $query = OvertimeRequest::where('id_companies', $user->id_companies)
            ->with(['employee.user', 'employee.department', 'employee.jobPosition', 'approver']);

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('date')) {
            $query->where('date', $request->input('date'));
        }

        $perPage = (int) $request->input('per_page', 15);
        $approvals = $query->orderByDesc('id_overtime_requests')->paginate($perPage);

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
