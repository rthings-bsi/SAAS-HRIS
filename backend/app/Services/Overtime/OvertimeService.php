<?php

namespace App\Services\Overtime;

use App\Models\Employee;
use App\Models\OvertimeRequest;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Validation\ValidationException;

class OvertimeService
{
    /**
     * Menghitung total durasi lembur dalam satuan jam.
     */
    public function calculateDurationHours(string $startTime, string $endTime): float
    {
        $start = Carbon::createFromFormat('H:i', substr($startTime, 0, 5));
        $end = Carbon::createFromFormat('H:i', substr($endTime, 0, 5));

        $minutes = $start->diffInMinutes($end, false);
        if ($minutes <= 0) {
            throw ValidationException::withMessages([
                'end_time' => 'Jam selesai lembur harus setelah jam mulai lembur.',
            ]);
        }

        return round($minutes / 60, 2);
    }

    /**
     * Memeriksa agar tidak ada pengajuan lembur yang tumpang tindih pada tanggal yang sama.
     */
    public function checkOverlap(int $employeeId, string $date, string $startTime, string $endTime, ?int $ignoreId = null): void
    {
        $start = substr($startTime, 0, 5);
        $end = substr($endTime, 0, 5);

        $query = OvertimeRequest::where('id_employees', $employeeId)
            ->where('date', $date)
            ->whereIn('status', ['pending', 'approved'])
            ->where(function ($q) use ($start, $end) {
                $q->where('start_time', '<', $end)
                  ->where('end_time', '>', $start);
            });

        if ($ignoreId) {
            $query->where('id_overtime_requests', '!=', $ignoreId);
        }

        if ($query->exists()) {
            throw ValidationException::withMessages([
                'start_time' => 'Terdapat pengajuan lembur yang tumpang tindih pada rentang waktu ini.',
            ]);
        }
    }

    /**
     * Mengajukan permohonan lembur baru.
     */
    public function applyOvertime(Employee $employee, array $data): OvertimeRequest
    {
        $this->checkOverlap($employee->id_employees, $data['date'], $data['start_time'], $data['end_time']);

        $duration = $this->calculateDurationHours($data['start_time'], $data['end_time']);

        return OvertimeRequest::create([
            'id_companies' => $employee->id_companies,
            'id_employees' => $employee->id_employees,
            'date' => $data['date'],
            'start_time' => $data['start_time'],
            'end_time' => $data['end_time'],
            'duration_hours' => $duration,
            'reason' => $data['reason'],
            'status' => 'pending',
        ]);
    }

    /**
     * Memproses persetujuan atau penolakan pengajuan lembur.
     */
    public function processApproval(OvertimeRequest $request, User $user, string $action, ?string $notes = null): OvertimeRequest
    {
        if ($request->id_companies !== $user->id_companies) {
            throw ValidationException::withMessages([
                'approval' => 'Pengajuan lembur tidak ditemukan pada instansi Anda.',
            ]);
        }

        if ($request->status !== 'pending') {
            throw ValidationException::withMessages([
                'status' => 'Pengajuan lembur ini sudah diproses sebelumnya.',
            ]);
        }

        $isApproved = in_array(strtolower($action), ['approved', 'approve'], true);

        $request->update([
            'status' => $isApproved ? 'approved' : 'rejected',
            'approved_by' => $user->id_users,
            'rejected_reason' => $isApproved ? null : ($notes ?: 'Ditolak oleh atasan/HR'),
        ]);

        return $request->fresh(['employee.user', 'approver']);
    }
}
