<?php

namespace App\Models\Traits;

use App\Models\Company;
use Illuminate\Database\Eloquent\Builder;

trait BelongsToCompany
{
    protected static function bootBelongsToCompany(): void
    {
        static::addGlobalScope('company', function (Builder $builder) {
            if (auth()->check() && auth()->user()->id_companies) {
                $builder->where($builder->getQuery()->from . '.id_companies', auth()->user()->id_companies);
            }
        });

        static::creating(function ($model) {
            if (auth()->check() && auth()->user()->id_companies && empty($model->id_companies)) {
                $model->id_companies = auth()->user()->id_companies;
            }
        });
    }

    public function company()
    {
        return $this->belongsTo(Company::class, 'id_companies', 'id_companies');
    }
}
