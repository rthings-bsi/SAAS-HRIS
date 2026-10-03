<?php

namespace App\Http\Requests\Organization;

use App\Http\Requests\BaseFormRequest;

class UpdateBranchRequest extends BaseFormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:100'],
            'address' => ['sometimes', 'required', 'string'],
            'latitude' => ['sometimes', 'required', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'required', 'numeric', 'between:-180,180'],
            'radius_meters' => ['sometimes', 'required', 'integer', 'min:1'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama cabang wajib diisi.',
            'name.string' => 'Nama cabang harus berupa teks.',
            'name.max' => 'Nama cabang maksimal 100 karakter.',
            'address.required' => 'Alamat cabang wajib diisi.',
            'address.string' => 'Alamat cabang harus berupa teks.',
            'latitude.required' => 'Latitude cabang wajib diisi.',
            'latitude.numeric' => 'Latitude harus berupa angka numerik.',
            'latitude.between' => 'Latitude harus berada dalam rentang -90 hingga 90.',
            'longitude.required' => 'Longitude cabang wajib diisi.',
            'longitude.numeric' => 'Longitude harus berupa angka numerik.',
            'longitude.between' => 'Longitude harus berada dalam rentang -180 hingga 180.',
            'radius_meters.required' => 'Radius cabang wajib diisi.',
            'radius_meters.integer' => 'Radius harus berupa bilangan bulat.',
            'radius_meters.min' => 'Radius minimal bernilai 1 meter.',
        ];
    }
}
