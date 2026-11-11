<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('overtime_request_items', function (Blueprint $table) {
            $table->id('id_overtime_request_items');
            $table->unsignedBigInteger('id_companies');
            $table->unsignedBigInteger('id_overtime_requests');
            $table->date('date');
            $table->date('end_date')->nullable();
            $table->time('start_time');
            $table->time('end_time');
            $table->decimal('duration_hours', 5, 2);
            $table->timestamps();

            $table->foreign('id_companies')
                ->references('id_companies')
                ->on('companies')
                ->onDelete('cascade');

            $table->foreign('id_overtime_requests')
                ->references('id_overtime_requests')
                ->on('overtime_requests')
                ->onDelete('cascade');

            $table->index(['id_companies', 'id_overtime_requests'], 'ori_company_request_idx');
            $table->index(['id_overtime_requests', 'date'], 'ori_request_date_idx');
        });

        Schema::table('overtime_requests', function (Blueprint $table) {
            $table->decimal('duration_hours', 6, 2)->change();
        });

        DB::table('overtime_requests')
            ->orderBy('id_overtime_requests')
            ->chunkById(100, function ($rows) {
                foreach ($rows as $row) {
                    $exists = DB::table('overtime_request_items')
                        ->where('id_overtime_requests', $row->id_overtime_requests)
                        ->exists();

                    if (! $exists) {
                        DB::table('overtime_request_items')->insert([
                            'id_companies' => $row->id_companies,
                            'id_overtime_requests' => $row->id_overtime_requests,
                            'date' => $row->date,
                            'end_date' => $row->end_date ?? $row->date,
                            'start_time' => $row->start_time,
                            'end_time' => $row->end_time,
                            'duration_hours' => $row->duration_hours,
                            'created_at' => $row->created_at ?? now(),
                            'updated_at' => $row->updated_at ?? now(),
                        ]);
                    }
                }
            }, 'id_overtime_requests');
    }

    public function down(): void
    {
        Schema::table('overtime_requests', function (Blueprint $table) {
            $table->decimal('duration_hours', 5, 2)->change();
        });

        Schema::dropIfExists('overtime_request_items');
    }
};
