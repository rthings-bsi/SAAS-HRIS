<?php

namespace App\Http\Requests\Overtime;

use App\Http\Requests\BaseFormRequest;

class ApplyOvertimeRequest extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'date' => ['required', 'date_format:Y-m-d'],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i', 'after:start_time'],
            'reason' => ['required', 'string', 'max:1000'],
        ];
    }

    public function messages(): array
    {
        return [
            'date.required' => 'Tanggal lembur wajib diisi.',
            'date.date_format' => 'Format tanggal lembur harus YYYY-MM-DD.',
            'start_time.required' => 'Jam mulai lembur wajib diisi.',
            'start_time.date_format' => 'Format jam mulai lembur harus JJ:MM (contoh: 17:00).',
            'end_time.required' => 'Jam selesai lembur wajib diisi.',
            'end_time.date_format' => 'Format jam selesai lembur harus JJ:MM (contoh: 21:00).',
            'end_time.after' => 'Jam selesai lembur harus setelah jam mulai lembur.',
            'reason.required' => 'Alasan / rincian tugas lembur wajib diisi.',
            'reason.string' => 'Alasan lembur harus berupa teks.',
            'reason.max' => 'Alasan lembur maksimal 1000 karakter.',
        ];
    }
}
