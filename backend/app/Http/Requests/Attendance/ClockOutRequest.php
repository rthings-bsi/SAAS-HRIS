<?php

namespace App\Http\Requests\Attendance;

use App\Http\Requests\BaseFormRequest;

class ClockOutRequest extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'photo' => ['nullable', 'image', 'max:2048'],
            'device_time' => ['nullable', 'date_format:Y-m-d H:i:s'],
        ];
    }

    public function messages(): array
    {
        return [
            'latitude.required' => 'Latitude wajib diisi.',
            'latitude.numeric' => 'Latitude harus berupa angka.',
            'latitude.between' => 'Latitude harus bernilai antara -90 dan 90.',
            'longitude.required' => 'Longitude wajib diisi.',
            'longitude.numeric' => 'Longitude harus berupa angka.',
            'longitude.between' => 'Longitude harus bernilai antara -180 dan 180.',
            'photo.image' => 'Berkas foto harus berupa gambar.',
            'photo.max' => 'Ukuran foto maksimal 2048 KB.',
            'device_time.date_format' => 'Format waktu perangkat harus Y-m-d H:i:s.',
        ];
    }
}
