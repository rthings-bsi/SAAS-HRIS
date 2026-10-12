<?php

namespace App\Http\Requests\Overtime;

use App\Http\Requests\BaseFormRequest;

class OvertimeApprovalActionRequest extends BaseFormRequest
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
            'action.required' => 'Aksi persetujuan lembur wajib ditentukan.',
            'action.string' => 'Aksi persetujuan harus berupa teks.',
            'action.in' => 'Aksi persetujuan harus berupa approved atau rejected.',
            'notes.string' => 'Catatan harus berupa teks.',
            'notes.max' => 'Catatan maksimal 1000 karakter.',
        ];
    }
}
