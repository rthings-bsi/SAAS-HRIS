<?php

namespace App\Http\Requests\Overtime;

use App\Http\Requests\BaseFormRequest;

class UpdateOvertimeRequest extends BaseFormRequest
{
    protected function prepareForValidation(): void
    {
        if ($this->has('remove_attachment') && is_string($this->input('remove_attachment'))) {
            $parsed = filter_var(
                $this->input('remove_attachment'),
                FILTER_VALIDATE_BOOLEAN,
                FILTER_NULL_ON_FAILURE
            );
            if ($parsed !== null) {
                $this->merge(['remove_attachment' => $parsed]);
            }
        }
    }

    public function rules(): array
    {
        return [
            'date' => ['sometimes', 'required', 'date_format:Y-m-d'],
            'end_date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            'start_time' => ['sometimes', 'required', 'date_format:H:i'],
            'end_time' => ['sometimes', 'required', 'date_format:H:i'],
            'overtime_type' => ['sometimes', 'nullable', 'string', 'max:60'],
            'reason_category' => ['sometimes', 'nullable', 'string', 'max:80'],
            'reason' => ['sometimes', 'required', 'string', 'max:1000'],
            'attachment' => ['sometimes', 'nullable', 'file', 'max:5120', 'mimes:txt,doc,docx,jpg,png,gif,xls,xlsx,pdf,jpeg'],
            'remove_attachment' => ['sometimes', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'date.required' => 'Tanggal lembur wajib diisi.',
            'date.date_format' => 'Format tanggal lembur harus YYYY-MM-DD.',
            'end_date.date_format' => 'Format tanggal berakhir lembur harus YYYY-MM-DD.',
            'start_time.required' => 'Jam mulai lembur wajib diisi.',
            'start_time.date_format' => 'Format jam mulai lembur harus JJ:MM (contoh: 17:00).',
            'end_time.required' => 'Jam selesai lembur wajib diisi.',
            'end_time.date_format' => 'Format jam selesai lembur harus JJ:MM (contoh: 21:00).',
            'overtime_type.string' => 'Tipe lembur harus berupa teks.',
            'overtime_type.max' => 'Tipe lembur maksimal 60 karakter.',
            'reason_category.string' => 'Alasan lembur harus berupa teks.',
            'reason_category.max' => 'Alasan lembur maksimal 80 karakter.',
            'reason.required' => 'Alasan / rincian tugas lembur wajib diisi.',
            'reason.string' => 'Alasan lembur harus berupa teks.',
            'reason.max' => 'Alasan lembur maksimal 1000 karakter.',
            'attachment.file' => 'Lampiran harus berupa berkas yang valid.',
            'attachment.max' => 'Ukuran berkas lampiran maksimal 5 MB.',
            'attachment.mimes' => 'Format berkas didukung: txt, doc, docx, jpg, png, gif, xls, xlsx, pdf, jpeg.',
            'remove_attachment.boolean' => 'Penanda hapus lampiran harus berupa nilai boolean.',
        ];
    }
}
