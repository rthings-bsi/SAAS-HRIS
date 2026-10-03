<?php

namespace App\Models;

use App\Models\Traits\BelongsToCompany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Branch extends Model
{
    use HasFactory, BelongsToCompany;

    protected $table = 'branches';
    protected $primaryKey = 'id_branches';

    protected $fillable = [
        'id_companies',
        'name',
        'address',
        'latitude',
        'longitude',
        'radius_meters',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
            'radius_meters' => 'integer',
        ];
    }

    public function employees(): HasMany
    {
        return $this->hasMany(Employee::class, 'id_branches', 'id_branches');
    }
}
