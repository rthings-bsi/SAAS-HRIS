<?php

namespace App\Http\Requests\Performance;

use App\Http\Requests\BaseFormRequest;

class StorePerformancePeriodRequest extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:100'],
            'start_date' => ['required', 'date'],
            'end_date' => ['required', 'date', 'after_or_equal:start_date'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama periode penilaian wajib diisi.',
            'name.max' => 'Nama periode penilaian maksimal 100 karakter.',
            'start_date.required' => 'Tanggal mulai periode wajib diisi.',
            'start_date.date' => 'Format tanggal mulai tidak valid.',
            'end_date.required' => 'Tanggal akhir periode wajib diisi.',
            'end_date.date' => 'Format tanggal akhir tidak valid.',
            'end_date.after_or_equal' => 'Tanggal akhir harus sama atau setelah tanggal mulai.',
        ];
    }
}
