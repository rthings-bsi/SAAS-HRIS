<?php

namespace App\Http\Requests\Shift;

use App\Http\Requests\BaseFormRequest;

class UpdateShiftRequest extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:100'],
            'start_time' => ['sometimes', 'required', 'regex:/^\d{2}:\d{2}(:\d{2})?$/'],
            'end_time' => ['sometimes', 'required', 'regex:/^\d{2}:\d{2}(:\d{2})?$/'],
            'late_tolerance_minutes' => ['nullable', 'integer', 'min:0'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama shift wajib diisi.',
            'name.string' => 'Nama shift harus berupa teks.',
            'name.max' => 'Nama shift tidak boleh lebih dari 100 karakter.',
            'start_time.required' => 'Jam mulai shift wajib diisi.',
            'start_time.regex' => 'Format jam mulai tidak valid (contoh: 08:00 atau 08:00:00).',
            'end_time.required' => 'Jam selesai shift wajib diisi.',
            'end_time.regex' => 'Format jam selesai tidak valid (contoh: 17:00 atau 17:00:00).',
            'late_tolerance_minutes.integer' => 'Toleransi keterlambatan harus berupa angka.',
            'late_tolerance_minutes.min' => 'Toleransi keterlambatan minimal 0 menit.',
        ];
    }
}
