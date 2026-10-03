<?php

namespace App\Http\Requests\Shift;

use App\Http\Requests\BaseFormRequest;
use Carbon\CarbonPeriod;
use Illuminate\Validation\Rule;

class AssignShiftRequest extends BaseFormRequest
{
    public function rules(): array
    {
        $companyId = auth()->user()?->id_companies;

        return [
            'id_employees' => [
                'required',
                'integer',
                Rule::exists('employees', 'id_employees')->where(function ($query) use ($companyId) {
                    if ($companyId) {
                        $query->where('id_companies', $companyId);
                    }
                }),
            ],
            'id_shifts' => [
                'required',
                'integer',
                Rule::exists('shifts', 'id_shifts')->where(function ($query) use ($companyId) {
                    if ($companyId) {
                        $query->where('id_companies', $companyId);
                    }
                }),
            ],
            'date' => ['nullable'],
            'dates' => ['nullable', 'array'],
            'dates.*' => ['date_format:Y-m-d'],
            'start_date' => ['nullable', 'date_format:Y-m-d', 'required_with:end_date'],
            'end_date' => ['nullable', 'date_format:Y-m-d', 'required_with:start_date', 'after_or_equal:start_date'],
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            $hasDate = $this->filled('date');
            $hasDates = $this->filled('dates') && is_array($this->input('dates')) && count($this->input('dates')) > 0;
            $hasRange = $this->filled('start_date') && $this->filled('end_date');

            if (!$hasDate && !$hasDates && !$hasRange) {
                $validator->errors()->add('date', 'Tanggal atau rentang tanggal wajib diisi.');
                return;
            }

            if ($hasDate) {
                $dateVal = $this->input('date');
                if (is_array($dateVal)) {
                    foreach ($dateVal as $index => $item) {
                        if (!is_string($item) || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $item) || !strtotime($item)) {
                            $validator->errors()->add("date.{$index}", 'Format tanggal pada daftar tidak valid (YYYY-MM-DD).');
                        }
                    }
                } elseif (!is_string($dateVal) || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateVal) || !strtotime($dateVal)) {
                    $validator->errors()->add('date', 'Format tanggal tidak valid (YYYY-MM-DD).');
                }
            }
        });
    }

    public function messages(): array
    {
        return [
            'id_employees.required' => 'Karyawan wajib dipilih.',
            'id_employees.integer' => 'ID karyawan harus berupa angka.',
            'id_employees.exists' => 'Karyawan tidak ditemukan atau tidak berada dalam perusahaan ini.',
            'id_shifts.required' => 'Shift wajib dipilih.',
            'id_shifts.integer' => 'ID shift harus berupa angka.',
            'id_shifts.exists' => 'Shift tidak ditemukan atau tidak berada dalam perusahaan ini.',
            'dates.array' => 'Daftar tanggal harus berupa array.',
            'dates.*.date_format' => 'Format setiap tanggal pada daftar harus YYYY-MM-DD.',
            'start_date.date_format' => 'Format tanggal mulai harus YYYY-MM-DD.',
            'start_date.required_with' => 'Tanggal mulai wajib diisi jika tanggal selesai ditentukan.',
            'end_date.date_format' => 'Format tanggal selesai harus YYYY-MM-DD.',
            'end_date.required_with' => 'Tanggal selesai wajib diisi jika tanggal mulai ditentukan.',
            'end_date.after_or_equal' => 'Tanggal selesai harus setelah atau sama dengan tanggal mulai.',
        ];
    }

    public function getDates(): array
    {
        if ($this->filled('start_date') && $this->filled('end_date')) {
            $period = CarbonPeriod::create($this->input('start_date'), $this->input('end_date'));
            $dates = [];
            foreach ($period as $date) {
                $dates[] = $date->format('Y-m-d');
            }
            return $dates;
        }

        if ($this->filled('dates') && is_array($this->input('dates'))) {
            return array_values(array_unique($this->input('dates')));
        }

        if ($this->filled('date')) {
            $date = $this->input('date');
            if (is_array($date)) {
                return array_values(array_unique($date));
            }
            return [$date];
        }

        return [];
    }
}
