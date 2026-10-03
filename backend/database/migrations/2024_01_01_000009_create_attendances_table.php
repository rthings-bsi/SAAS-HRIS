<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('attendances', function (Blueprint $table) {
            $table->id('id_attendances');
            $table->unsignedBigInteger('id_companies');
            $table->unsignedBigInteger('id_employees');
            $table->date('date');

            $table->time('clock_in_time')->nullable();
            $table->decimal('clock_in_latitude', 10, 8)->nullable();
            $table->decimal('clock_in_longitude', 11, 8)->nullable();
            $table->string('clock_in_photo_path', 255)->nullable();
            $table->unsignedInteger('clock_in_distance_meters')->nullable();

            $table->time('clock_out_time')->nullable();
            $table->decimal('clock_out_latitude', 10, 8)->nullable();
            $table->decimal('clock_out_longitude', 11, 8)->nullable();
            $table->string('clock_out_photo_path', 255)->nullable();
            $table->unsignedInteger('clock_out_distance_meters')->nullable();

            $table->enum('status', ['on_time', 'late', 'early_leave', 'absent', 'leave', 'holiday'])->default('absent');
            $table->unsignedInteger('late_duration_minutes')->default(0);
            $table->unsignedInteger('early_leave_minutes')->default(0);
            $table->text('notes')->nullable();

            $table->timestamps();

            $table->unique(['id_employees', 'date']);

            $table->foreign('id_companies')
                ->references('id_companies')
                ->on('companies')
                ->onDelete('cascade');

            $table->foreign('id_employees')
                ->references('id_employees')
                ->on('employees')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('attendances');
    }
};
