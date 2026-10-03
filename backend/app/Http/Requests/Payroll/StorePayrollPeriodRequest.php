<?php

namespace App\Http\Requests\Payroll;

use App\Http\Requests\BaseFormRequest;

class StorePayrollPeriodRequest extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:100'],
            'start_date' => ['required', 'date'],
            'end_date' => ['required', 'date', 'after_or_equal:start_date'],
            'payment_date' => ['required', 'date', 'after_or_equal:start_date'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama periode penggajian wajib diisi.',
            'name.max' => 'Nama periode penggajian maksimal 100 karakter.',
            'start_date.required' => 'Tanggal mulai periode wajib diisi.',
            'start_date.date' => 'Format tanggal mulai periode tidak valid.',
            'end_date.required' => 'Tanggal selesai periode wajib diisi.',
            'end_date.date' => 'Format tanggal selesai periode tidak valid.',
            'end_date.after_or_equal' => 'Tanggal selesai harus sama atau setelah tanggal mulai.',
            'payment_date.required' => 'Tanggal pembayaran wajib diisi.',
            'payment_date.date' => 'Format tanggal pembayaran tidak valid.',
            'payment_date.after_or_equal' => 'Tanggal pembayaran harus sama atau setelah tanggal mulai.',
        ];
    }
}
