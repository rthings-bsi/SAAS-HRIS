<?php

namespace App\Http\Requests\Leave;

use App\Http\Requests\BaseFormRequest;

class ApplyLeaveRequest extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'id_leave_types' => ['required', 'integer', 'exists:leave_types,id_leave_types'],
            'start_date' => ['required', 'date_format:Y-m-d'],
            'end_date' => ['required', 'date_format:Y-m-d', 'after_or_equal:start_date'],
            'reason' => ['required', 'string', 'max:1000'],
            'attachment' => ['nullable', 'file', 'max:4096', 'mimes:pdf,jpg,jpeg,png'],
        ];
    }

    public function messages(): array
    {
        return [
            'id_leave_types.required' => 'Jenis cuti wajib dipilih.',
            'id_leave_types.integer' => 'ID jenis cuti harus berupa angka.',
            'id_leave_types.exists' => 'Jenis cuti tidak ditemukan.',
            'start_date.required' => 'Tanggal mulai cuti wajib diisi.',
            'start_date.date_format' => 'Format tanggal mulai cuti tidak valid (gunakan format YYYY-MM-DD).',
            'end_date.required' => 'Tanggal selesai cuti wajib diisi.',
            'end_date.date_format' => 'Format tanggal selesai cuti tidak valid (gunakan format YYYY-MM-DD).',
            'end_date.after_or_equal' => 'Tanggal selesai cuti harus sama atau setelah tanggal mulai cuti.',
            'reason.required' => 'Alasan cuti wajib diisi.',
            'reason.string' => 'Alasan cuti harus berupa teks.',
            'reason.max' => 'Alasan cuti maksimal 1000 karakter.',
            'attachment.file' => 'Berkas lampiran harus berupa dokumen atau gambar.',
            'attachment.max' => 'Ukuran berkas lampiran maksimal 4MB (4096 KB).',
            'attachment.mimes' => 'Berkas lampiran harus berformat PDF, JPG, JPEG, atau PNG.',
        ];
    }
}
