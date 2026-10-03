<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('shifts', function (Blueprint $table) {
            $table->id('id_shifts');
            $table->unsignedBigInteger('id_companies');
            $table->string('name', 100);
            $table->time('start_time');
            $table->time('end_time');
            $table->unsignedInteger('late_tolerance_minutes')->default(15);
            $table->timestamps();

            $table->foreign('id_companies')
                ->references('id_companies')
                ->on('companies')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('shifts');
    }
};
