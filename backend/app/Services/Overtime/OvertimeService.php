<?php

namespace App\Services\Overtime;

use App\Models\Employee;
use App\Models\OvertimeRequest;
use App\Models\OvertimeRequestItem;
use App\Models\User;
use App\Services\Notification\NotificationService;
use Carbon\Carbon;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class OvertimeService
{
    public function __construct(
        protected ?NotificationService $notificationService = null
    ) {
        $this->notificationService = $notificationService ?? app(NotificationService::class);
    }

    private function resolveDateString(mixed $value): string
    {
        if ($value instanceof Carbon) {
            return $value->format('Y-m-d');
        }
        $str = (string) $value;
        return strlen($str) >= 10 ? substr($str, 0, 10) : $str;
    }

    private function parseWindow(string $date, ?string $endDate, string $startTime, string $endTime): array
    {
        $resolvedEndDate = (! empty($endDate)) ? $endDate : $date;
        $startDt = Carbon::createFromFormat('Y-m-d H:i', $date . ' ' . substr($startTime, 0, 5));
        $endDt = Carbon::createFromFormat('Y-m-d H:i', $resolvedEndDate . ' ' . substr($endTime, 0, 5));

        return [$startDt, $endDt, $resolvedEndDate];
    }

    /**
     * Memvalidasi, mengecek tumpang tindih, dan mengurutkan daftar sesi lembur.
     *
     * @param  array<int, array{date: string, end_date?: ?string, start_time: string, end_time: string}>  $entries
     * @return array{
     *   items: array<int, array{date: string, end_date: string, start_time: string, end_time: string, duration_hours: float}>,
     *   header_date: string,
     *   header_end_date: string,
     *   header_start_time: string,
     *   header_end_time: string,
     *   total_duration: float
     * }
     */
    private function normalizeAndValidateEntries(int $employeeId, array $entries, ?int $ignoreId = null): array
    {
        if (empty($entries)) {
            throw ValidationException::withMessages([
                'entries' => 'Pilih minimal 1 sesi lembur.',
            ]);
        }

        /** @var array<int, array{start: Carbon, end: Carbon}> $batchWindows */
        $batchWindows = [];
        $normalized = [];

        foreach ($entries as $idx => $entry) {
            $date = $entry['date'];
            $endDate = ! empty($entry['end_date']) ? $entry['end_date'] : $date;
            $startTime = $entry['start_time'];
            $endTime = $entry['end_time'];

            try {
                $duration = $this->calculateDurationHours($startTime, $endTime, $date, $endDate);
            } catch (ValidationException) {
                throw ValidationException::withMessages([
                    "entries.{$idx}.end_time" => "Jam selesai lembur pada tanggal {$date} harus setelah jam mulai lembur.",
                ]);
            }

            [$candStart, $candEnd, $resolvedEndDate] = $this->parseWindow($date, $endDate, $startTime, $endTime);

            foreach ($batchWindows as $existingWindow) {
                if ($existingWindow['start']->lt($candEnd) && $existingWindow['end']->gt($candStart)) {
                    throw ValidationException::withMessages([
                        "entries.{$idx}.start_time" => "Jadwal lembur pada tanggal {$date} bertabrakan dengan sesi lain dalam pengajuan ini.",
                    ]);
                }
            }
            $batchWindows[] = ['start' => $candStart, 'end' => $candEnd];

            try {
                $this->checkOverlap($employeeId, $date, $startTime, $endTime, $ignoreId, $resolvedEndDate);
            } catch (ValidationException) {
                throw ValidationException::withMessages([
                    "entries.{$idx}.start_time" => "Tanggal {$date} sudah memiliki pengajuan lembur yang tumpang tindih pada jam ini.",
                ]);
            }

            $normalized[] = [
                'date' => $date,
                'end_date' => $resolvedEndDate,
                'start_time' => $startTime,
                'end_time' => $endTime,
                'duration_hours' => $duration,
                '_start_ts' => $candStart->timestamp,
                '_end_ts' => $candEnd->timestamp,
            ];
        }

        usort($normalized, static function (array $a, array $b): int {
            $cmp = $a['_start_ts'] <=> $b['_start_ts'];
            return $cmp !== 0 ? $cmp : ($a['_end_ts'] <=> $b['_end_ts']);
        });

        $firstItem = $normalized[0];
        $latestEndItem = $normalized[0];
        $totalDuration = 0.0;

        foreach ($normalized as $item) {
            $totalDuration += $item['duration_hours'];
            if ($item['_end_ts'] >= $latestEndItem['_end_ts']) {
                $latestEndItem = $item;
            }
        }

        $cleanItems = array_map(static fn (array $item): array => [
            'date' => $item['date'],
            'end_date' => $item['end_date'],
            'start_time' => $item['start_time'],
            'end_time' => $item['end_time'],
            'duration_hours' => $item['duration_hours'],
        ], $normalized);

        return [
            'items' => $cleanItems,
            'header_date' => $firstItem['date'],
            'header_end_date' => $latestEndItem['end_date'],
            'header_start_time' => $firstItem['start_time'],
            'header_end_time' => $latestEndItem['end_time'],
            'total_duration' => round($totalDuration, 2),
        ];
    }

    /**
     * Menghitung total durasi lembur dalam satuan jam (mendukung lintas hari).
     */
    public function calculateDurationHours(string $startTime, string $endTime, ?string $startDate = null, ?string $endDate = null): float
    {
        $sDate = $startDate ?: '2000-01-01';
        $eDate = (! empty($endDate)) ? $endDate : $sDate;
        [$startDt, $endDt] = $this->parseWindow($sDate, $eDate, $startTime, $endTime);

        $minutes = $startDt->diffInMinutes($endDt, false);
        if ($minutes <= 0) {
            throw ValidationException::withMessages([
                'end_time' => 'Jam selesai lembur harus setelah jam mulai lembur.',
            ]);
        }

        if ($minutes > 1440) {
            throw ValidationException::withMessages([
                'end_time' => 'Durasi satu sesi lembur maksimal 24 jam.',
            ]);
        }

        return round($minutes / 60, 2);
    }

    /**
     * Memeriksa tumpang tindih interval waktu lembur terhadap pengajuan aktif di database.
     */
    public function checkOverlap(
        int $employeeId,
        string $date,
        string $startTime,
        string $endTime,
        ?int $ignoreId = null,
        ?string $endDate = null
    ): void {
        [$candStart, $candEnd, $resolvedEndDate] = $this->parseWindow($date, $endDate, $startTime, $endTime);

        $query = OvertimeRequest::with('items')
            ->where('id_employees', $employeeId)
            ->whereIn('status', ['pending', 'approved'])
            ->where(function ($outer) use ($date, $resolvedEndDate) {
                $outer->where(function ($parentRange) use ($date, $resolvedEndDate) {
                    $parentRange->where('date', '<=', $resolvedEndDate)
                        ->where(function ($q) use ($date) {
                            $q->where('end_date', '>=', $date)
                                ->orWhere(function ($sub) use ($date) {
                                    $sub->whereNull('end_date')
                                        ->where('date', '>=', $date);
                                });
                        });
                })->orWhereHas('items', function ($iq) use ($date, $resolvedEndDate) {
                    $iq->where('date', '<=', $resolvedEndDate)
                        ->where(function ($q) use ($date) {
                            $q->where('end_date', '>=', $date)
                                ->orWhere(function ($sub) use ($date) {
                                    $sub->whereNull('end_date')
                                        ->where('date', '>=', $date);
                                });
                        });
                });
            });

        if ($ignoreId) {
            $query->where('id_overtime_requests', '!=', $ignoreId);
        }

        foreach ($query->get() as $existing) {
            $windows = $existing->items->isNotEmpty() ? $existing->items : collect([$existing]);

            foreach ($windows as $win) {
                $exDate = $this->resolveDateString($win->date);
                $exEndDate = $win->end_date ? $this->resolveDateString($win->end_date) : $exDate;
                [$exStart, $exEnd] = $this->parseWindow($exDate, $exEndDate, $win->start_time, $win->end_time);

                if ($exStart->lt($candEnd) && $exEnd->gt($candStart)) {
                    throw ValidationException::withMessages([
                        'start_time' => 'Terdapat pengajuan lembur yang tumpang tindih pada rentang waktu ini.',
                    ]);
                }
            }
        }
    }

    /**
     * Mengajukan permohonan lembur baru (satu sesi).
     */
    public function applyOvertime(Employee $employee, array $data, ?UploadedFile $attachment = null): OvertimeRequest
    {
        $endDate = ! empty($data['end_date']) ? $data['end_date'] : $data['date'];

        $duration = $this->calculateDurationHours(
            $data['start_time'],
            $data['end_time'],
            $data['date'],
            $endDate
        );

        $this->checkOverlap(
            $employee->id_employees,
            $data['date'],
            $data['start_time'],
            $data['end_time'],
            null,
            $endDate
        );

        $attachmentPath = $attachment
            ? $attachment->store("{$employee->id_companies}/overtimes", 'public')
            : null;

        $overtime = DB::transaction(function () use ($employee, $data, $endDate, $duration, $attachmentPath): OvertimeRequest {
            $header = OvertimeRequest::create([
                'id_companies' => $employee->id_companies,
                'id_employees' => $employee->id_employees,
                'date' => $data['date'],
                'end_date' => $endDate,
                'start_time' => $data['start_time'],
                'end_time' => $data['end_time'],
                'duration_hours' => $duration,
                'overtime_type' => $data['overtime_type'] ?? null,
                'reason_category' => $data['reason_category'] ?? null,
                'reason' => $data['reason'],
                'attachment_path' => $attachmentPath,
                'status' => 'pending',
            ]);

            OvertimeRequestItem::create([
                'id_companies' => $employee->id_companies,
                'id_overtime_requests' => $header->id_overtime_requests,
                'date' => $data['date'],
                'end_date' => $endDate,
                'start_time' => $data['start_time'],
                'end_time' => $data['end_time'],
                'duration_hours' => $duration,
            ]);

            return $header;
        });

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

        return $overtime->fresh(['items', 'employee.user', 'employee.shift']);
    }

    /**
     * Mengajukan permohonan lembur konsolidasi untuk satu atau beberapa hari / sesi.
     *
     * @param  array<int, array{date: string, end_date?: ?string, start_time: string, end_time: string}>  $entries
     */
    public function applyOvertimeBatch(
        Employee $employee,
        array $entries,
        string $reason,
        ?string $overtimeType = null,
        ?string $reasonCategory = null,
        ?UploadedFile $attachment = null
    ): OvertimeRequest {
        $bundle = $this->normalizeAndValidateEntries($employee->id_employees, $entries);

        $attachmentPath = $attachment
            ? $attachment->store("{$employee->id_companies}/overtimes", 'public')
            : null;

        $overtime = DB::transaction(function () use (
            $employee,
            $bundle,
            $reason,
            $overtimeType,
            $reasonCategory,
            $attachmentPath
        ): OvertimeRequest {
            $header = OvertimeRequest::create([
                'id_companies' => $employee->id_companies,
                'id_employees' => $employee->id_employees,
                'date' => $bundle['header_date'],
                'end_date' => $bundle['header_end_date'],
                'start_time' => $bundle['header_start_time'],
                'end_time' => $bundle['header_end_time'],
                'duration_hours' => $bundle['total_duration'],
                'overtime_type' => $overtimeType,
                'reason_category' => $reasonCategory,
                'reason' => $reason,
                'attachment_path' => $attachmentPath,
                'status' => 'pending',
            ]);

            foreach ($bundle['items'] as $item) {
                OvertimeRequestItem::create([
                    'id_companies' => $employee->id_companies,
                    'id_overtime_requests' => $header->id_overtime_requests,
                    'date' => $item['date'],
                    'end_date' => $item['end_date'],
                    'start_time' => $item['start_time'],
                    'end_time' => $item['end_time'],
                    'duration_hours' => $item['duration_hours'],
                ]);
            }

            return $header;
        });

        try {
            $employeeName = $employee->user?->name ?? 'Karyawan';
            $count = count($bundle['items']);
            $totalHours = $bundle['total_duration'];
            $dateRange = $bundle['header_date'] === $bundle['header_end_date']
                ? $bundle['header_date']
                : "{$bundle['header_date']} s/d {$bundle['header_end_date']}";

            $body = $count === 1
                ? "{$employeeName} mengajukan permohonan lembur pada {$bundle['header_date']} ({$bundle['header_start_time']} - {$bundle['header_end_time']}, {$totalHours} jam)."
                : "{$employeeName} mengajukan permohonan lembur ({$count} sesi, {$dateRange}, total {$totalHours} jam).";

            $this->notificationService->notifyAdmins(
                $employee->id_companies,
                'overtime',
                'Pengajuan Lembur Baru',
                $body,
                [
                    'url' => '/overtime',
                    'id_overtime_requests' => $overtime->id_overtime_requests,
                    'count' => $count,
                    'total_hours' => $totalHours,
                    'status' => 'pending',
                ],
                $employee->id_users
            );
        } catch (\Throwable) {
            // Abaikan kegagalan notifikasi agar transaksi lembur tidak terputus
        }

        return $overtime->fresh(['items', 'employee.user', 'employee.shift']);
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

        $fresh = $request->fresh(['items', 'employee.user', 'employee.shift', 'approver']);

        try {
            $empUserId = $fresh->employee?->id_users;
            if ($empUserId) {
                $dateStr = $this->resolveDateString($fresh->date);
                $endStr = $fresh->end_date ? $this->resolveDateString($fresh->end_date) : $dateStr;
                $dateLabel = $endStr !== $dateStr ? "{$dateStr} s/d {$endStr}" : $dateStr;
                $statusText = $isApproved ? 'Disetujui' : 'Ditolak';
                $message = $isApproved
                    ? "Pengajuan lembur Anda pada tanggal {$dateLabel} ({$fresh->duration_hours} jam) telah disetujui."
                    : "Pengajuan lembur Anda pada tanggal {$dateLabel} ditolak. Alasan: " . ($notes ?: 'Ditolak oleh atasan/HR.');

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

    /**
     * Merevisi pengajuan lembur yang masih berstatus pending.
     */
    public function updateOvertime(
        OvertimeRequest $request,
        Employee $employee,
        array $data,
        ?UploadedFile $attachment = null
    ): OvertimeRequest {
        if ($request->id_employees !== $employee->id_employees || $request->id_companies !== $employee->id_companies) {
            throw ValidationException::withMessages([
                'overtime' => 'Anda tidak memiliki hak akses untuk mengubah pengajuan lembur ini.',
            ]);
        }

        if ($request->status !== 'pending') {
            throw ValidationException::withMessages([
                'status' => 'Hanya pengajuan lembur dengan status menunggu yang dapat direvisi.',
            ]);
        }

        $hasEntries = array_key_exists('entries', $data);
        $hasScheduleFields = array_key_exists('date', $data)
            || array_key_exists('end_date', $data)
            || array_key_exists('start_time', $data)
            || array_key_exists('end_time', $data);

        $bundle = null;
        $singleSchedule = null;

        if ($hasEntries) {
            $bundle = $this->normalizeAndValidateEntries(
                $employee->id_employees,
                $data['entries'],
                $request->id_overtime_requests
            );
        } elseif ($hasScheduleFields) {
            $origDate = $this->resolveDateString($request->date);
            $date = $data['date'] ?? $origDate;

            if (array_key_exists('end_date', $data) && ! empty($data['end_date'])) {
                $endDate = $data['end_date'];
            } elseif (isset($data['date']) && $data['date'] !== $origDate) {
                $origEnd = $request->end_date ? $this->resolveDateString($request->end_date) : $origDate;
                $dayOffset = Carbon::createFromFormat('Y-m-d', $origDate)->startOfDay()
                    ->diffInDays(Carbon::createFromFormat('Y-m-d', $origEnd)->startOfDay(), false);
                $endDate = Carbon::createFromFormat('Y-m-d', $date)
                    ->addDays(max(0, (int) $dayOffset))
                    ->format('Y-m-d');
            } else {
                $endDate = $request->end_date ? $this->resolveDateString($request->end_date) : $date;
            }

            $startDay = Carbon::createFromFormat('Y-m-d', $date)->startOfDay();
            $endDay = Carbon::createFromFormat('Y-m-d', $endDate)->startOfDay();
            if ($endDay->lt($startDay)) {
                throw ValidationException::withMessages([
                    'end_date' => 'Tanggal berakhir lembur tidak boleh sebelum tanggal mulai.',
                ]);
            }

            $startTime = $data['start_time'] ?? $request->start_time;
            $endTime = $data['end_time'] ?? $request->end_time;
            $duration = $this->calculateDurationHours($startTime, $endTime, $date, $endDate);

            $this->checkOverlap(
                $employee->id_employees,
                $date,
                $startTime,
                $endTime,
                $request->id_overtime_requests,
                $endDate
            );

            $singleSchedule = [
                'date' => $date,
                'end_date' => $endDate,
                'start_time' => $startTime,
                'end_time' => $endTime,
                'duration_hours' => $duration,
            ];
        }

        $oldAttachmentPath = $request->attachment_path;
        $attachmentPath = $oldAttachmentPath;
        if ($attachment) {
            $attachmentPath = $attachment->store("{$employee->id_companies}/overtimes", 'public');
        } elseif (! empty($data['remove_attachment'])) {
            $attachmentPath = null;
        }

        $commonFields = [
            'overtime_type' => array_key_exists('overtime_type', $data) ? $data['overtime_type'] : $request->overtime_type,
            'reason_category' => array_key_exists('reason_category', $data) ? $data['reason_category'] : $request->reason_category,
            'reason' => $data['reason'] ?? $request->reason,
            'attachment_path' => $attachmentPath,
        ];

        DB::transaction(function () use ($request, $employee, $bundle, $singleSchedule, $commonFields): void {
            if ($bundle !== null) {
                $request->update(array_merge($commonFields, [
                    'date' => $bundle['header_date'],
                    'end_date' => $bundle['header_end_date'],
                    'start_time' => $bundle['header_start_time'],
                    'end_time' => $bundle['header_end_time'],
                    'duration_hours' => $bundle['total_duration'],
                ]));

                $request->items()->delete();
                foreach ($bundle['items'] as $item) {
                    OvertimeRequestItem::create([
                        'id_companies' => $employee->id_companies,
                        'id_overtime_requests' => $request->id_overtime_requests,
                        'date' => $item['date'],
                        'end_date' => $item['end_date'],
                        'start_time' => $item['start_time'],
                        'end_time' => $item['end_time'],
                        'duration_hours' => $item['duration_hours'],
                    ]);
                }
                return;
            }

            if ($singleSchedule !== null) {
                $request->update(array_merge($commonFields, $singleSchedule));

                $request->items()->delete();
                OvertimeRequestItem::create([
                    'id_companies' => $employee->id_companies,
                    'id_overtime_requests' => $request->id_overtime_requests,
                    'date' => $singleSchedule['date'],
                    'end_date' => $singleSchedule['end_date'],
                    'start_time' => $singleSchedule['start_time'],
                    'end_time' => $singleSchedule['end_time'],
                    'duration_hours' => $singleSchedule['duration_hours'],
                ]);
                return;
            }

            $request->update($commonFields);
        });

        if ($oldAttachmentPath && $oldAttachmentPath !== $attachmentPath) {
            $stillReferenced = OvertimeRequest::where('attachment_path', $oldAttachmentPath)->exists();
            if (! $stillReferenced) {
                Storage::disk('public')->delete($oldAttachmentPath);
            }
        }

        return $request->fresh(['items', 'employee.user', 'employee.shift', 'approver']);
    }

    /**
     * Membatalkan pengajuan lembur yang masih berstatus pending oleh karyawan pembuat.
     */
    public function cancelOvertime(OvertimeRequest $request, Employee $employee, ?string $reason = null): OvertimeRequest
    {
        if ($request->id_employees !== $employee->id_employees || $request->id_companies !== $employee->id_companies) {
            throw ValidationException::withMessages([
                'overtime' => 'Anda tidak memiliki hak akses untuk membatalkan pengajuan lembur ini.',
            ]);
        }

        if ($request->status !== 'pending') {
            throw ValidationException::withMessages([
                'status' => 'Hanya pengajuan lembur dengan status menunggu yang dapat dibatalkan.',
            ]);
        }

        $request->update([
            'status' => 'cancelled',
            'rejected_reason' => $reason ?: 'Dibatalkan oleh karyawan',
        ]);

        return $request->fresh(['items', 'employee.user', 'employee.shift', 'approver']);
    }
}
