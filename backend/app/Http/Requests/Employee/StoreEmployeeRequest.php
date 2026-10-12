<?php

namespace App\Http\Requests\Employee;

use App\Http\Requests\BaseFormRequest;
use Illuminate\Validation\Rule;

class StoreEmployeeRequest extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:150'],
            'email' => ['required', 'string', 'email', 'max:150', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'role' => ['nullable', 'string', Rule::in(['owner', 'hr', 'manager', 'employee'])],
            'id_branches' => ['nullable'],
            'id_departments' => ['nullable'],
            'id_job_positions' => ['nullable'],
            'department_name' => ['nullable', 'string', 'max:100'],
            'job_position_name' => ['nullable', 'string', 'max:100'],
            'id_shifts' => ['nullable', 'integer', Rule::exists('shifts', 'id_shifts')],
            'annual_leave_quota' => ['nullable', 'integer', 'min:0'],
            'nik' => ['required', 'string', 'max:50'],
            'phone' => ['nullable', 'string', 'max:30'],
            'gender' => ['required', 'in:male,female'],
            'birth_date' => ['nullable', 'date_format:Y-m-d'],
            'hire_date' => ['required', 'date_format:Y-m-d'],
            'employment_status' => ['nullable', 'in:permanent,contract,probation,intern'],
            'basic_salary' => ['nullable', 'numeric', 'min:0'],
            'allowance_fixed' => ['nullable', 'numeric', 'min:0'],
            'bank_name' => ['nullable', 'string', 'max:50'],
            'bank_account_number' => ['nullable', 'string', 'max:50'],
            'bank_account_holder' => ['nullable', 'string', 'max:100'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama karyawan wajib diisi.',
            'name.string' => 'Nama karyawan harus berupa teks.',
            'name.max' => 'Nama karyawan tidak boleh lebih dari 150 karakter.',
            'email.required' => 'Email wajib diisi.',
            'email.string' => 'Email harus berupa teks.',
            'email.email' => 'Format email tidak valid.',
            'email.max' => 'Email tidak boleh lebih dari 150 karakter.',
            'email.unique' => 'Email sudah terdaftar.',
            'password.required' => 'Kata sandi wajib diisi.',
            'password.string' => 'Kata sandi harus berupa teks.',
            'password.min' => 'Kata sandi minimal harus 8 karakter.',
            'id_shifts.exists' => 'Shift kerja tidak ditemukan.',
            'nik.required' => 'NIK karyawan wajib diisi.',
            'nik.string' => 'NIK harus berupa teks.',
            'nik.max' => 'NIK tidak boleh lebih dari 50 karakter.',
            'phone.string' => 'Nomor telepon harus berupa teks.',
            'phone.max' => 'Nomor telepon tidak boleh lebih dari 30 karakter.',
            'gender.required' => 'Jenis kelamin wajib dipilih.',
            'gender.in' => 'Jenis kelamin harus salah satu dari: male, female.',
            'birth_date.date_format' => 'Format tanggal lahir harus YYYY-MM-DD.',
            'hire_date.required' => 'Tanggal mulai kerja wajib diisi.',
            'hire_date.date_format' => 'Format tanggal mulai kerja harus YYYY-MM-DD.',
            'employment_status.in' => 'Status kerja harus salah satu dari: permanent, contract, probation, intern.',
            'basic_salary.numeric' => 'Gaji pokok harus berupa angka.',
            'basic_salary.min' => 'Gaji pokok minimal 0.',
            'allowance_fixed.numeric' => 'Tunjangan tetap harus berupa angka.',
            'allowance_fixed.min' => 'Tunjangan tetap minimal 0.',
            'bank_name.string' => 'Nama bank harus berupa teks.',
            'bank_name.max' => 'Nama bank tidak boleh lebih dari 50 karakter.',
            'bank_account_number.string' => 'Nomor rekening bank harus berupa teks.',
            'bank_account_number.max' => 'Nomor rekening bank tidak boleh lebih dari 50 karakter.',
            'bank_account_holder.string' => 'Nama pemilik rekening harus berupa teks.',
            'bank_account_holder.max' => 'Nama pemilik rekening tidak boleh lebih dari 100 karakter.',
        ];
    }
}
