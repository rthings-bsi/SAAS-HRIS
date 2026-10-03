<?php

namespace App\Services\Auth;

use App\Models\Branch;
use App\Models\Company;
use App\Models\Shift;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class RegisterCompanyService
{
    public function register(array $data): array
    {
        return DB::transaction(function () use ($data) {
            $baseSlug = Str::slug($data['company_name']);
            if (empty($baseSlug)) {
                $baseSlug = 'company';
            }

            $slug = $baseSlug;
            $counter = 1;
            while (Company::where('slug', $slug)->exists()) {
                $slug = $baseSlug . '-' . $counter;
                $counter++;
            }

            $company = Company::create([
                'name' => $data['company_name'],
                'slug' => $slug,
                'email' => $data['email'],
                'phone' => $data['phone'] ?? null,
                'address' => $data['address'] ?? null,
                'subscription_status' => 'trial',
                'trial_ends_at' => now()->addDays(14),
            ]);

            $branch = Branch::create([
                'id_companies' => $company->id_companies,
                'name' => 'Kantor Utama',
                'address' => $data['address'] ?? 'Kantor Utama',
                'latitude' => -6.2088,
                'longitude' => 106.8456,
                'radius_meters' => 50,
            ]);

            $shift = Shift::create([
                'id_companies' => $company->id_companies,
                'name' => 'Shift Normal',
                'start_time' => '08:00:00',
                'end_time' => '17:00:00',
                'late_tolerance_minutes' => 15,
            ]);

            $user = User::create([
                'id_companies' => $company->id_companies,
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => Hash::make($data['password']),
                'role' => 'owner',
                'is_active' => true,
            ]);

            $token = $user->createToken('access_token')->plainTextToken;

            return [
                'token' => $token,
                'access_token' => $token,
                'token_type' => 'Bearer',
                'user' => $user->load('company'),
                'company' => $company,
            ];
        });
    }
}
