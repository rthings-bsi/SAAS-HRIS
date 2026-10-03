<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('employee_shifts', function (Blueprint $table) {
            $table->id('id_employee_shifts');
            $table->unsignedBigInteger('id_companies');
            $table->unsignedBigInteger('id_employees');
            $table->unsignedBigInteger('id_shifts');
            $table->date('date');
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

            $table->foreign('id_shifts')
                ->references('id_shifts')
                ->on('shifts')
                ->onDelete('restrict');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('employee_shifts');
    }
};
