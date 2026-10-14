<?php

namespace App\Services\Overtime;

use App\Models\Employee;
use App\Models\OvertimeRequest;
use App\Models\User;
use App\Services\Notification\NotificationService;
use Carbon\Carbon;
use Illuminate\Validation\ValidationException;

class OvertimeService
{
    public function __construct(
        protected ?NotificationService $notificationService = null
    ) {
        $this->notificationService = $notificationService ?? app(NotificationService::class);
    }
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

        $overtime = OvertimeRequest::create([
            'id_companies' => $employee->id_companies,
            'id_employees' => $employee->id_employees,
            'date' => $data['date'],
            'start_time' => $data['start_time'],
            'end_time' => $data['end_time'],
            'duration_hours' => $duration,
            'reason' => $data['reason'],
            'status' => 'pending',
        ]);

        try {
            $employeeName = $employee->user?->name ?? 'Karyawan';
            $this->notificationService->notifyAdmins(
                $employee->id_companies,
                'overtime',
                'Pengajuan Lembur Baru',
                "{$employeeName} mengajukan permohonan lembur pada {$data['date']} ({$data['start_time']} - {$data['end_time']}, {$duration} jam).",
                [
                    'url' => '/overtime',
                    'id_overtime_requests' => $overtime->id_overtime_requests,
                    'status' => 'pending',
                ],
                $employee->id_users
            );
        } catch (\Throwable) {
            // Abaikan kegagalan notifikasi agar transaksi lembur tidak terputus
        }

        return $overtime;
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

        $fresh = $request->fresh(['employee.user', 'approver']);

        try {
            $empUserId = $fresh->employee?->id_users;
            if ($empUserId) {
                $statusText = $isApproved ? 'Disetujui' : 'Ditolak';
                $message = $isApproved
                    ? "Pengajuan lembur Anda pada tanggal {$fresh->date} ({$fresh->duration_hours} jam) telah disetujui."
                    : "Pengajuan lembur Anda pada tanggal {$fresh->date} ditolak. Alasan: " . ($notes ?: 'Ditolak oleh atasan/HR.');

                $this->notificationService->send(
                    $fresh->id_companies,
                    $empUserId,
                    'overtime',
                    "Pengajuan Lembur {$statusText}",
                    $message,
                    [
                        'url' => '/overtime',
                        'id_overtime_requests' => $fresh->id_overtime_requests,
                        'status' => $fresh->status,
                    ]
                );
            }
        } catch (\Throwable) {
            // Abaikan kendala pengiriman notifikasi agar alur persetujuan tetap sukses
        }

        return $fresh;
    }
}
