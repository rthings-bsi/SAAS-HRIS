<?php

namespace App\Services\Attendance;

use App\Exceptions\AttendanceException;
use App\Models\Attendance;
use App\Models\Employee;
use App\Models\Shift;
use Carbon\Carbon;
use Illuminate\Http\UploadedFile;

class AttendanceService
{
    public function getTodayAttendance(Employee $employee, string $date): array
    {
        $employee->loadMissing('company');
        $shift = $this->resolveShift($employee, $date);

        $attendance = Attendance::where('id_employees', $employee->id_employees)
            ->whereDate('date', $date)
            ->first();

        return [
            'employee' => $employee,
            'branch' => $employee->branch,
            'shift' => $shift,
            'attendance' => $attendance,
        ];
    }

    public function resolveShift(Employee $employee, string $date): ?Shift
    {
        return $employee->shift
            ?? Shift::where('id_companies', $employee->id_companies)->orderBy('id_shifts', 'asc')->first();
    }

    public function clockIn(Employee $employee, array $data, ?UploadedFile $photo): Attendance
    {
        $branch = $employee->branch;
        if (! $branch) {
            throw new AttendanceException('Karyawan belum memiliki kantor cabang penugasan.', 422);
        }

        $distance = GeofenceService::calculateDistanceInMeters(
            (float) $data['latitude'],
            (float) $data['longitude'],
            (float) $branch->latitude,
            (float) $branch->longitude
        );

        if ($distance > $branch->radius_meters) {
            throw new AttendanceException(
                'Jarak perangkat ' . round($distance) . 'm, melebihi batas radius kantor (' . $branch->radius_meters . 'm).',
                422
            );
        }

        $deviceTime = ! empty($data['device_time'])
            ? Carbon::parse($data['device_time'])
            : Carbon::now();
        $date = $deviceTime->toDateString();

        $existingAttendance = Attendance::where('id_employees', $employee->id_employees)
            ->whereDate('date', $date)
            ->first();

        if ($existingAttendance && ! empty($existingAttendance->clock_in_time)) {
            throw new AttendanceException('Anda sudah melakukan clock-in hari ini.', 422);
        }

        if (! $photo) {
            throw new AttendanceException('Foto presensi wajib diunggah.', 422);
        }

        $photoPath = $photo->store("{$employee->id_companies}/attendances", 'public');

        $shift = $this->resolveShift($employee, $date);
        $lateCalculation = $this->calculateLate($shift, $deviceTime, $date);

        if ($existingAttendance) {
            $existingAttendance->update([
                'clock_in_time' => $deviceTime->toTimeString(),
                'clock_in_latitude' => $data['latitude'],
                'clock_in_longitude' => $data['longitude'],
                'clock_in_photo_path' => $photoPath,
                'clock_in_distance_meters' => (int) round($distance),
                'status' => $lateCalculation['status'],
                'late_duration_minutes' => $lateCalculation['late_duration_minutes'],
            ]);

            return $existingAttendance;
        }

        return Attendance::create([
            'id_companies' => $employee->id_companies,
            'id_employees' => $employee->id_employees,
            'date' => $date,
            'clock_in_time' => $deviceTime->toTimeString(),
            'clock_in_latitude' => $data['latitude'],
            'clock_in_longitude' => $data['longitude'],
            'clock_in_photo_path' => $photoPath,
            'clock_in_distance_meters' => (int) round($distance),
            'status' => $lateCalculation['status'],
            'late_duration_minutes' => $lateCalculation['late_duration_minutes'],
        ]);
    }

    public function clockOut(Employee $employee, array $data, ?UploadedFile $photo = null): Attendance
    {
        $branch = $employee->branch;
        if (! $branch) {
            throw new AttendanceException('Karyawan belum memiliki kantor cabang penugasan.', 422);
        }

        $deviceTime = ! empty($data['device_time'])
            ? Carbon::parse($data['device_time'])
            : Carbon::now();
        $date = $deviceTime->toDateString();

        $attendance = Attendance::where('id_employees', $employee->id_employees)
            ->whereDate('date', $date)
            ->first();

        if (! $attendance || empty($attendance->clock_in_time)) {
            throw new AttendanceException('Presensi clock-in belum ditemukan untuk hari ini.', 422);
        }

        if (! empty($attendance->clock_out_time)) {
            throw new AttendanceException('Anda sudah melakukan clock-out hari ini.', 422);
        }

        $distance = GeofenceService::calculateDistanceInMeters(
            (float) $data['latitude'],
            (float) $data['longitude'],
            (float) $branch->latitude,
            (float) $branch->longitude
        );

        if ($distance > $branch->radius_meters) {
            throw new AttendanceException(
                'Jarak perangkat ' . round($distance) . 'm, melebihi batas radius kantor (' . $branch->radius_meters . 'm).',
                422
            );
        }

        $shift = $this->resolveShift($employee, $date);
        $earlyLeaveMinutes = $this->calculateEarlyLeave($shift, $deviceTime, $date);

        $updateData = [
            'clock_out_time' => $deviceTime->toTimeString(),
            'clock_out_latitude' => $data['latitude'],
            'clock_out_longitude' => $data['longitude'],
            'clock_out_distance_meters' => (int) round($distance),
            'early_leave_minutes' => $earlyLeaveMinutes,
        ];

        if ($photo) {
            $updateData['clock_out_photo_path'] = $photo->store("{$employee->id_companies}/attendances", 'public');
        }

        $attendance->update($updateData);

        return $attendance;
    }

    public function calculateLate(?Shift $shift, Carbon $clockInTime, string $date): array
    {
        if (! $shift || empty($shift->start_time)) {
            return ['status' => 'on_time', 'late_duration_minutes' => 0];
        }

        $shiftStartTime = Carbon::parse($date . ' ' . $shift->start_time);
        $toleranceMinutes = (int) ($shift->late_tolerance_minutes ?? 0);
        $cutoffTime = $shiftStartTime->copy()->addMinutes($toleranceMinutes);

        if ($clockInTime->gt($cutoffTime)) {
            return [
                'status' => 'late',
                'late_duration_minutes' => (int) $shiftStartTime->diffInMinutes($clockInTime),
            ];
        }

        return ['status' => 'on_time', 'late_duration_minutes' => 0];
    }

    public function calculateEarlyLeave(?Shift $shift, Carbon $clockOutTime, string $date): int
    {
        if (! $shift || empty($shift->end_time)) {
            return 0;
        }

        $shiftEndTime = Carbon::parse($date . ' ' . $shift->end_time);

        if ($clockOutTime->lt($shiftEndTime)) {
            return (int) $clockOutTime->diffInMinutes($shiftEndTime);
        }

        return 0;
    }

    public function getHistory(Employee $employee, array $filters, int $perPage = 15)
    {
        $query = Attendance::where('id_employees', $employee->id_employees);

        if (! empty($filters['month'])) {
            $query->where('date', 'like', $filters['month'] . '%');
        } elseif (! empty($filters['start_date']) && ! empty($filters['end_date'])) {
            $query->whereBetween('date', [$filters['start_date'], $filters['end_date']]);
        } elseif (! empty($filters['start_date'])) {
            $query->where('date', '>=', $filters['start_date']);
        } elseif (! empty($filters['end_date'])) {
            $query->where('date', '<=', $filters['end_date']);
        }

        return $query->orderBy('date', 'desc')
            ->orderBy('id_attendances', 'desc')
            ->paginate($perPage);
    }

    public function getRecapData(int $companyId, ?string $date = null, ?string $month = null): array
    {
        $query = Attendance::where('id_companies', $companyId);

        if ($date) {
            $period = $date;
            $query->whereDate('date', $date);
        } elseif ($month) {
            $period = $month;
            $query->where('date', 'like', "{$month}%");
        } else {
            $period = Carbon::today()->toDateString();
            $query->whereDate('date', $period);
        }

        $attendances = $query->with([
            'employee.user',
            'employee.company',
        ])->get();

        $totalEmployees = Employee::where('id_companies', $companyId)->count();
        $totalPresent = $attendances->count();
        $onTimeCount = $attendances->where('status', 'on_time')->count();
        $lateCount = $attendances->where('status', 'late')->count();
        $earlyLeaveCount = $attendances->filter(fn ($a) => $a->early_leave_minutes > 0 || $a->status === 'early_leave')->count();

        return [
            'period' => $period,
            'total_employees' => $totalEmployees,
            'total_present' => $totalPresent,
            'on_time' => $onTimeCount,
            'late' => $lateCount,
            'early_leave' => $earlyLeaveCount,
            'attendances' => $attendances,
        ];
    }
}
