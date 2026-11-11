<?php

namespace App\Http\Requests\Overtime;

use App\Http\Requests\BaseFormRequest;
use Carbon\Carbon;

class ApplyOvertimeRequest extends BaseFormRequest
{
    protected function prepareForValidation(): void
    {
        $entries = $this->input('entries');
        if (is_string($entries)) {
            $decoded = json_decode($entries, true);
            if (is_array($decoded)) {
                $this->merge(['entries' => $decoded]);
            }
        }
    }

    public function rules(): array
    {
        $commonRules = [
            'overtime_type' => ['nullable', 'string', 'max:60'],
            'reason_category' => ['nullable', 'string', 'max:80'],
            'reason' => ['required', 'string', 'max:1000'],
            'attachment' => ['nullable', 'file', 'max:5120', 'mimes:txt,doc,docx,jpg,png,gif,xls,xlsx,pdf,jpeg'],
        ];

        if ($this->has('entries')) {
            return array_merge($commonRules, [
                'entries' => ['required', 'array', 'min:1', 'max:62'],
                'entries.*.date' => ['required', 'date_format:Y-m-d'],
                'entries.*.end_date' => ['nullable', 'date_format:Y-m-d'],
                'entries.*.start_time' => ['required', 'date_format:H:i'],
                'entries.*.end_time' => ['required', 'date_format:H:i'],
            ]);
        }

        return array_merge($commonRules, [
            'date' => ['required', 'date_format:Y-m-d'],
            'end_date' => ['nullable', 'date_format:Y-m-d'],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i'],
        ]);
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            if ($this->has('entries')) {
                $entries = $this->input('entries');
                if (! is_array($entries)) {
                    return;
                }

                foreach ($entries as $idx => $entry) {
                    if (! is_array($entry)) {
                        continue;
                    }
                    $this->validateTimeWindow(
                        $validator,
                        $entry['date'] ?? null,
                        $entry['end_date'] ?? null,
                        $entry['start_time'] ?? null,
                        $entry['end_time'] ?? null,
                        "entries.{$idx}.end_date",
                        "entries.{$idx}.end_time",
                        $entry['date'] ?? ('sesi ' . ($idx + 1))
                    );
                }
                return;
            }

            $this->validateTimeWindow(
                $validator,
                $this->input('date'),
                $this->input('end_date'),
                $this->input('start_time'),
                $this->input('end_time'),
                'end_date',
                'end_time',
                null
            );
        });
    }

    protected function validateTimeWindow(
        $validator,
        mixed $date,
        mixed $endDate,
        mixed $startTime,
        mixed $endTime,
        string $endDateField,
        string $endTimeField,
        ?string $dateContext
    ): void {
        if (
            ! is_string($date)
            || ! preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)
            || ! is_string($startTime)
            || ! preg_match('/^\d{2}:\d{2}$/', $startTime)
            || ! is_string($endTime)
            || ! preg_match('/^\d{2}:\d{2}$/', $endTime)
        ) {
            return;
        }

        $resolvedEndDate = (is_string($endDate) && $endDate !== '') ? $endDate : $date;
        if (! preg_match('/^\d{4}-\d{2}-\d{2}$/', $resolvedEndDate)) {
            return;
        }

        try {
            $startDay = Carbon::createFromFormat('Y-m-d', $date)->startOfDay();
            $endDay = Carbon::createFromFormat('Y-m-d', $resolvedEndDate)->startOfDay();
            if ($endDay->lt($startDay)) {
                $validator->errors()->add(
                    $endDateField,
                    'Tanggal berakhir lembur tidak boleh sebelum tanggal mulai.'
                );
                return;
            }

            $startDt = Carbon::createFromFormat('Y-m-d H:i', "{$date} {$startTime}");
            $endDt = Carbon::createFromFormat('Y-m-d H:i', "{$resolvedEndDate} {$endTime}");
            $minutes = $startDt->diffInMinutes($endDt, false);

            if ($minutes <= 0) {
                $msg = $dateContext
                    ? "Jam selesai lembur pada tanggal {$dateContext} harus setelah jam mulai lembur."
                    : 'Jam selesai lembur harus setelah jam mulai lembur.';
                $validator->errors()->add($endTimeField, $msg);
                return;
            }

            if ($minutes > 1440) {
                $validator->errors()->add(
                    $endTimeField,
                    'Durasi satu sesi lembur maksimal 24 jam.'
                );
            }
        } catch (\Throwable) {
            // Validasi format tanggal/jam sudah ditangani aturan dasar.
        }
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
            'entries.required' => 'Daftar jadwal lembur wajib diisi.',
            'entries.array' => 'Format daftar jadwal lembur tidak valid.',
            'entries.min' => 'Pilih minimal 1 sesi lembur.',
            'entries.max' => 'Maksimal 62 sesi lembur dalam satu pengajuan.',
            'entries.*.date.required' => 'Tanggal mulai wajib diisi pada setiap sesi lembur.',
            'entries.*.date.date_format' => 'Format tanggal lembur harus YYYY-MM-DD.',
            'entries.*.end_date.date_format' => 'Format tanggal berakhir lembur harus YYYY-MM-DD.',
            'entries.*.start_time.required' => 'Jam mulai lembur wajib diisi pada setiap sesi.',
            'entries.*.start_time.date_format' => 'Format jam mulai lembur harus JJ:MM (contoh: 17:00).',
            'entries.*.end_time.required' => 'Jam selesai lembur wajib diisi pada setiap sesi.',
            'entries.*.end_time.date_format' => 'Format jam selesai lembur harus JJ:MM (contoh: 21:00).',
            'overtime_type.string' => 'Tipe lembur harus berupa teks.',
            'overtime_type.max' => 'Tipe lembur maksimal 60 karakter.',
            'reason_category.string' => 'Alasan lembur harus berupa teks.',
            'reason_category.max' => 'Alasan lembur maksimal 80 karakter.',
            'reason.required' => 'Keterangan / rincian tugas lembur wajib diisi.',
            'reason.string' => 'Keterangan lembur harus berupa teks.',
            'reason.max' => 'Keterangan lembur maksimal 1000 karakter.',
            'attachment.file' => 'Lampiran harus berupa berkas yang valid.',
            'attachment.max' => 'Ukuran berkas lampiran maksimal 5 MB.',
            'attachment.mimes' => 'Format berkas didukung: txt, doc, docx, jpg, png, gif, xls, xlsx, pdf, jpeg.',
        ];
    }
}
