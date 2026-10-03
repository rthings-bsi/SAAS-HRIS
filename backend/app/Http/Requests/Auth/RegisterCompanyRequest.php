<?php

namespace App\Http\Requests\Auth;

use App\Http\Requests\BaseFormRequest;

class RegisterCompanyRequest extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'company_name' => ['required', 'string', 'max:150'],
            'name' => ['required', 'string', 'max:150'],
            'email' => ['required', 'string', 'email', 'max:150', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'phone' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string'],
        ];
    }

    public function messages(): array
    {
        return [
            'company_name.required' => 'Nama perusahaan wajib diisi.',
            'company_name.string' => 'Nama perusahaan harus berupa teks.',
            'company_name.max' => 'Nama perusahaan tidak boleh lebih dari 150 karakter.',
            'name.required' => 'Nama penanggung jawab wajib diisi.',
            'name.string' => 'Nama harus berupa teks.',
            'name.max' => 'Nama tidak boleh lebih dari 150 karakter.',
            'email.required' => 'Email wajib diisi.',
            'email.email' => 'Format email tidak valid.',
            'email.unique' => 'Email sudah terdaftar.',
            'email.max' => 'Email tidak boleh lebih dari 150 karakter.',
            'password.required' => 'Password wajib diisi.',
            'password.min' => 'Password minimal harus 8 karakter.',
            'password.confirmed' => 'Konfirmasi password tidak cocok.',
            'phone.string' => 'Nomor telepon harus berupa teks.',
            'phone.max' => 'Nomor telepon tidak boleh lebih dari 30 karakter.',
            'address.string' => 'Alamat harus berupa teks.',
        ];
    }
}
