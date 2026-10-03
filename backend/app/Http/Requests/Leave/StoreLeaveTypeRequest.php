<?php

namespace App\Http\Requests\Leave;

use App\Http\Requests\BaseFormRequest;

class StoreLeaveTypeRequest extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:100'],
            'quota_days' => ['required', 'integer', 'min:0'],
            'is_paid' => ['required', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama jenis cuti wajib diisi.',
            'name.string' => 'Nama jenis cuti harus berupa teks.',
            'name.max' => 'Nama jenis cuti maksimal 100 karakter.',
            'quota_days.required' => 'Kuota hari cuti wajib diisi.',
            'quota_days.integer' => 'Kuota hari cuti harus berupa angka bulat.',
            'quota_days.min' => 'Kuota hari cuti minimal 0 hari.',
            'is_paid.required' => 'Status cuti berbayar wajib ditentukan.',
            'is_paid.boolean' => 'Status cuti berbayar harus bernilai true atau false.',
        ];
    }
}
