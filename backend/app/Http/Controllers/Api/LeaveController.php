<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\LeaveException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Leave\ApplyLeaveRequest;
use App\Http\Requests\Leave\ApprovalActionRequest;
use App\Http\Requests\Leave\StoreLeaveTypeRequest;
use App\Models\LeaveRequest;
use App\Services\Leave\LeaveService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LeaveController extends Controller
{
    public function __construct(
        protected LeaveService $leaveService
    ) {}

    public function types(): JsonResponse
    {
        $user = auth()->user();
        $employee = $user?->employee;
        $quota = $employee ? ($employee->annual_leave_quota ?? 12) : 12;
        $types = LeaveService::getStandardTypes($quota);

        return $this->successResponse($types, 'Daftar jenis cuti berhasil diambil.');
    }

    public function storeType(StoreLeaveTypeRequest $request): JsonResponse
    {
        $user = auth()->user();

        if (! in_array($user?->role, ['owner', 'hr', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Hanya HR atau Owner yang dapat membuat jenis cuti.', null, 403);
        }

        $leaveType = [
            'id_leave_types' => rand(10, 99),
            'id_companies' => $user->id_companies,
            'name' => $request->validated('name'),
            'quota_days' => $request->validated('quota_days'),
            'is_paid' => $request->validated('is_paid'),
        ];

        return $this->successResponse($leaveType, 'Jenis cuti berhasil dibuat.', 201);
    }

    public function balance(Request $request): JsonResponse
    {
        $user = auth()->user();
        $employee = $user?->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 404);
        }

        $year = $request->filled('year') ? (int) $request->input('year') : null;
        $balance = $this->leaveService->getEmployeeLeaveBalance($employee, $year);

        return $this->successResponse($balance, 'Informasi kuota cuti berhasil diambil.');
    }

    public function myRequests(Request $request): JsonResponse
    {
        $user = auth()->user();
        $employee = $user?->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 404);
        }

        $query = LeaveRequest::where('id_employees', $employee->id_employees)
            ->with(['approver']);

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('year')) {
            $query->whereYear('start_date', $request->input('year'));
        }

        $perPage = (int) $request->input('per_page', 15);
        $requests = $query->orderByDesc('id_leave_requests')->paginate($perPage);

        return $this->successResponse($requests, 'Riwayat pengajuan cuti berhasil diambil.');
    }

    public function applyLeave(ApplyLeaveRequest $request): JsonResponse
    {
        $user = auth()->user();
        $employee = $user?->employee;

        if (! $employee) {
            return $this->errorResponse('Profil karyawan tidak ditemukan.', null, 404);
        }

        try {
            $leaveRequest = $this->leaveService->applyLeave(
                $employee,
                $request->validated(),
                $request->file('attachment')
            );

            return $this->successResponse(
                $leaveRequest,
                'Pengajuan cuti berhasil diajukan.',
                201
            );
        } catch (LeaveException $e) {
            return $this->errorResponse($e->getMessage(), $e->getErrors(), $e->getCode() ?: 422);
        }
    }

    public function approvals(Request $request): JsonResponse
    {
        $user = auth()->user();

        if (! in_array($user?->role, ['owner', 'hr', 'manager', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki izin melihat daftar persetujuan cuti.', null, 403);
        }

        $query = LeaveRequest::where('id_companies', $user->id_companies)
            ->with(['employee.user', 'approver']);

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        $perPage = (int) $request->input('per_page', 15);
        $approvals = $query->orderByDesc('id_leave_requests')->paginate($perPage);

        return $this->successResponse($approvals, 'Daftar pengajuan cuti untuk persetujuan berhasil diambil.');
    }

    public function takeApprovalAction(ApprovalActionRequest $request, int|string $id): JsonResponse
    {
        $user = auth()->user();

        if (! in_array($user?->role, ['owner', 'hr', 'manager', 'superadmin'])) {
            return $this->errorResponse('Akses ditolak. Anda tidak memiliki izin memproses pengajuan cuti.', null, 403);
        }

        $leaveRequest = LeaveRequest::where('id_companies', $user->id_companies)
            ->where('id_leave_requests', $id)
            ->first();

        if (! $leaveRequest) {
            return $this->errorResponse('Pengajuan cuti tidak ditemukan.', null, 404);
        }

        try {
            $updated = $this->leaveService->processApproval(
                $leaveRequest,
                $user,
                $request->validated('action'),
                $request->validated('notes')
            );

            $actionText = $updated->status === 'approved' ? 'disetujui' : 'ditolak';

            return $this->successResponse($updated, "Pengajuan cuti berhasil {$actionText}.");
        } catch (LeaveException $e) {
            return $this->errorResponse($e->getMessage(), $e->getErrors(), $e->getCode() ?: 422);
        }
    }
}
