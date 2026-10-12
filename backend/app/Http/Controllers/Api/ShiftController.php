<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Shift\AssignShiftRequest;
use App\Http\Requests\Shift\StoreShiftRequest;
use App\Http\Requests\Shift\UpdateShiftRequest;
use App\Models\Employee;
use App\Models\EmployeeShift;
use App\Models\Shift;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class ShiftController extends Controller
{
    public function index(): JsonResponse
    {
        $shifts = Shift::orderBy('id_shifts', 'desc')->get();

        return $this->successResponse($shifts, 'Daftar shift berhasil diambil.');
    }

    public function store(StoreShiftRequest $request): JsonResponse
    {
        $shift = Shift::create([
            'id_companies' => auth()->user()?->id_companies,
            'name' => $request->input('name'),
            'start_time' => $request->input('start_time'),
            'end_time' => $request->input('end_time'),
            'late_tolerance_minutes' => $request->input('late_tolerance_minutes', 15),
        ]);

        return $this->successResponse($shift, 'Shift berhasil dibuat.', 201);
    }

    public function show(string|int $id_shifts): JsonResponse
    {
        $shift = Shift::findOrFail($id_shifts);

        return $this->successResponse($shift, 'Detail shift berhasil diambil.');
    }

    public function update(UpdateShiftRequest $request, string|int $id_shifts): JsonResponse
    {
        $shift = Shift::findOrFail($id_shifts);
        $shift->update($request->validated());

        return $this->successResponse($shift, 'Shift berhasil diperbarui.');
    }

    public function destroy(string|int $id_shifts): JsonResponse
    {
        $shift = Shift::findOrFail($id_shifts);

        if ($shift->employeeShifts()->exists()) {
            return $this->errorResponse('Shift tidak dapat dihapus karena masih digunakan pada jadwal karyawan.', null, 422);
        }

        $shift->delete();

        return $this->successResponse(null, 'Shift berhasil dihapus.');
    }

    public function assignShift(AssignShiftRequest $request): JsonResponse
    {
        $dates = $request->getDates();
        $employeeId = $request->input('id_employees');
        $shiftId = $request->input('id_shifts');

        $assigned = [];
        DB::transaction(function () use ($dates, $employeeId, $shiftId, &$assigned) {
            $companyId = auth()->user()?->id_companies
                ?? Employee::withoutGlobalScopes()->find($employeeId)?->id_companies
                ?? 1;

            foreach ($dates as $date) {
                $assigned[] = EmployeeShift::updateOrCreate(
                    [
                        'id_companies' => $companyId,
                        'id_employees' => $employeeId,
                        'date' => $date,
                    ],
                    [
                        'id_shifts' => $shiftId,
                    ]
                );
            }
        });

        return $this->successResponse($assigned, 'Jadwal shift berhasil ditugaskan.', 200);
    }
}
