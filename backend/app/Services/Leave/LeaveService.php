<?php

namespace App\Services\Leave;

use App\Exceptions\LeaveException;
use App\Models\Employee;
use App\Models\LeaveRequest;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class LeaveService
{
    public static function getStandardTypes(int $annualQuota = 12): array
    {
        return [
            ['id_leave_types' => 1, 'name' => 'Cuti Tahunan', 'quota_days' => $annualQuota, 'is_paid' => true],
            ['id_leave_types' => 2, 'name' => 'Cuti Sakit', 'quota_days' => 14, 'is_paid' => true],
            ['id_leave_types' => 3, 'name' => 'Izin Khusus', 'quota_days' => 5, 'is_paid' => true],
            ['id_leave_types' => 4, 'name' => 'Cuti Melahirkan', 'quota_days' => 90, 'is_paid' => true],
            ['id_leave_types' => 5, 'name' => 'Cuti Tanpa Gaji', 'quota_days' => 30, 'is_paid' => false],
        ];
    }

    public function resolveTypeName(int|string|null $identifier): string
    {
        if (is_numeric($identifier)) {
            return match ((int) $identifier) {
                2 => 'Cuti Sakit',
                3 => 'Izin Khusus',
                4 => 'Cuti Melahirkan',
                5 => 'Cuti Tanpa Gaji',
                default => 'Cuti Tahunan',
            };
        }

        return ! empty($identifier) ? (string) $identifier : 'Cuti Tahunan';
    }

    public function calculateTotalDays(string $startDate, string $endDate): int
    {
        $start = Carbon::parse($startDate)->startOfDay();
        $end = Carbon::parse($endDate)->startOfDay();

        if ($end->lt($start)) {
            throw new LeaveException('Tanggal selesai cuti tidak boleh mendahului tanggal mulai cuti.', 422);
        }

        return (int) $start->diffInDays($end) + 1;
    }

    public function getUsedDays(int $employeeId, string|int $leaveType, int $year): int
    {
        $typeName = $this->resolveTypeName($leaveType);

        return (int) LeaveRequest::where('id_employees', $employeeId)
            ->where('leave_type', $typeName)
            ->where('status', 'approved')
            ->whereYear('start_date', $year)
            ->sum('total_days');
    }

    public function getPendingDays(int $employeeId, string|int $leaveType, int $year): int
    {
        $typeName = $this->resolveTypeName($leaveType);

        return (int) LeaveRequest::where('id_employees', $employeeId)
            ->where('leave_type', $typeName)
            ->where('status', 'pending')
            ->whereYear('start_date', $year)
            ->sum('total_days');
    }

    public function checkQuotaBalance(Employee $employee, string $leaveTypeName, int $quotaDays, int $requestedDays, int $year): void
    {
        $usedDays = $this->getUsedDays($employee->id_employees, $leaveTypeName, $year);
        $pendingDays = $this->getPendingDays($employee->id_employees, $leaveTypeName, $year);

        $remainingQuota = $quotaDays - ($usedDays + $pendingDays);

        if ($requestedDays > $remainingQuota) {
            throw new LeaveException(
                "Sisa kuota cuti tidak mencukupi. Kuota tersedia: {$remainingQuota} hari, diajukan: {$requestedDays} hari.",
                422
            );
        }
    }

    public function checkOverlap(int $employeeId, string $startDate, string $endDate, ?int $excludeRequestId = null): void
    {
        $query = LeaveRequest::where('id_employees', $employeeId)
            ->whereIn('status', ['pending', 'approved'])
            ->where(function ($q) use ($startDate, $endDate) {
                $q->where('start_date', '<=', $endDate)
                  ->where('end_date', '>=', $startDate);
            });

        if ($excludeRequestId) {
            $query->where('id_leave_requests', '!=', $excludeRequestId);
        }

        if ($query->exists()) {
            throw new LeaveException('Tanggal pengajuan cuti bertabrakan dengan pengajuan cuti lain yang sudah ada (berstatus pending atau disetujui).', 422);
        }
    }

    public function getEmployeeLeaveBalance(Employee $employee, ?int $year = null): array
    {
        $year = $year ?? (int) Carbon::now()->year;
        $standardTypes = self::getStandardTypes($employee->annual_leave_quota ?? 12);

        return array_map(function (array $type) use ($employee, $year) {
            $usedDays = $this->getUsedDays($employee->id_employees, $type['name'], $year);
            $pendingDays = $this->getPendingDays($employee->id_employees, $type['name'], $year);

            return [
                'id_leave_types' => $type['id_leave_types'],
                'name' => $type['name'],
                'quota_days' => (int) $type['quota_days'],
                'used_days' => $usedDays,
                'pending_days' => $pendingDays,
                'remaining_days' => max(0, $type['quota_days'] - $usedDays),
                'available_days' => max(0, $type['quota_days'] - ($usedDays + $pendingDays)),
                'is_paid' => (bool) $type['is_paid'],
                'year' => $year,
            ];
        }, $standardTypes);
    }

    public function applyLeave(Employee $employee, array $data, ?UploadedFile $attachment = null): LeaveRequest
    {
        $leaveTypeName = ! empty($data['leave_type'])
            ? (string) $data['leave_type']
            : $this->resolveTypeName($data['id_leave_types'] ?? 1);

        $startDate = $data['start_date'];
        $endDate = $data['end_date'];
        $totalDays = $this->calculateTotalDays($startDate, $endDate);
        $year = (int) Carbon::parse($startDate)->year;

        // Quota check
        $standardTypes = self::getStandardTypes($employee->annual_leave_quota ?? 12);
        $matchedType = collect($standardTypes)->firstWhere('name', $leaveTypeName)
            ?? ['quota_days' => ($employee->annual_leave_quota ?? 12), 'is_paid' => true];

        $this->checkQuotaBalance($employee, $leaveTypeName, $matchedType['quota_days'], $totalDays, $year);

        // Check overlapping dates
        $this->checkOverlap($employee->id_employees, $startDate, $endDate);

        // Store attachment if provided
        $attachmentUrl = null;
        if ($attachment) {
            $attachmentPath = $attachment->store("{$employee->id_companies}/leaves", 'public');
            $attachmentUrl = Storage::url($attachmentPath);
        }

        return LeaveRequest::create([
            'id_companies' => $employee->id_companies,
            'id_employees' => $employee->id_employees,
            'leave_type' => $leaveTypeName,
            'is_paid' => (bool) ($matchedType['is_paid'] ?? true),
            'start_date' => $startDate,
            'end_date' => $endDate,
            'total_days' => $totalDays,
            'reason' => $data['reason'],
            'attachment_url' => $attachmentUrl,
            'status' => 'pending',
        ]);
    }

    public function processApproval(LeaveRequest $leaveRequest, User $actor, string $action, ?string $notes = null): LeaveRequest
    {
        if ($leaveRequest->id_companies !== $actor->id_companies) {
            throw new LeaveException('Pengajuan cuti tidak ditemukan.', 404);
        }

        if ($leaveRequest->status !== 'pending') {
            throw new LeaveException('Pengajuan cuti ini sudah diproses sebelumnya.', 422);
        }

        $isApprove = in_array(strtolower($action), ['approved', 'approve'], true);

        $leaveRequest->update([
            'status' => $isApprove ? 'approved' : 'rejected',
            'approved_by' => $actor->id_users,
            'rejected_reason' => $isApprove ? null : $notes,
        ]);

        return $leaveRequest->fresh(['employee.user', 'approver']);
    }
}
