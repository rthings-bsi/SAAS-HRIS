<?php

namespace App\Http\Requests\Organization;

use App\Http\Requests\BaseFormRequest;

class UpdateJobPositionRequest extends BaseFormRequest
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
            'name.required' => 'Nama posisi jabatan wajib diisi.',
            'name.string' => 'Nama posisi jabatan harus berupa teks.',
            'name.max' => 'Nama posisi jabatan maksimal 100 karakter.',
        ];
    }
}
