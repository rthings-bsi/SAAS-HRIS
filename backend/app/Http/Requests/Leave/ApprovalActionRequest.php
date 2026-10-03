<?php

namespace App\Http\Requests\Leave;

use App\Http\Requests\BaseFormRequest;

class ApprovalActionRequest extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'action' => ['required', 'string', 'in:approved,rejected,approve,reject'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }

    public function messages(): array
    {
        return [
            'action.required' => 'Aksi persetujuan cuti wajib ditentukan.',
            'action.string' => 'Aksi persetujuan harus berupa teks.',
            'action.in' => 'Aksi persetujuan harus berupa approved atau rejected.',
            'notes.string' => 'Catatan harus berupa teks.',
            'notes.max' => 'Catatan maksimal 1000 karakter.',
        ];
    }
}
