<?php

namespace App\Http\Requests\SuperAdmin;

use App\Http\Requests\BaseFormRequest;
use Illuminate\Validation\Rule;

class UpdateCompanyRequest extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:150'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:20'],
            'address' => ['sometimes', 'nullable', 'string'],
            'subscription_status' => [
                'sometimes',
                'required',
                Rule::in(['trial', 'active', 'suspended', 'cancelled']),
            ],
            'trial_ends_at' => ['sometimes', 'nullable', 'date'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama perusahaan wajib diisi.',
            'name.string' => 'Nama perusahaan harus berupa teks.',
            'name.max' => 'Nama perusahaan maksimal 150 karakter.',
            'phone.string' => 'Nomor telepon harus berupa teks.',
            'phone.max' => 'Nomor telepon maksimal 20 karakter.',
            'address.string' => 'Alamat harus berupa teks.',
            'subscription_status.required' => 'Status langganan wajib diisi.',
            'subscription_status.in' => 'Status langganan harus salah satu dari: trial, active, suspended, cancelled.',
            'trial_ends_at.date' => 'Format tanggal batas masa uji coba tidak valid.',
        ];
    }
}
