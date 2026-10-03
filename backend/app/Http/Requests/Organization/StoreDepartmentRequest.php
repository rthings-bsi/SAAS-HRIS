<?php

namespace App\Http\Requests\Organization;

use App\Http\Requests\BaseFormRequest;

class StoreDepartmentRequest extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:100'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama departemen wajib diisi.',
            'name.string' => 'Nama departemen harus berupa teks.',
            'name.max' => 'Nama departemen maksimal 100 karakter.',
        ];
    }
}
