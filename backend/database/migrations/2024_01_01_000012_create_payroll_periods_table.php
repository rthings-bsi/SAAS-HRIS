<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payroll_periods', function (Blueprint $table) {
            $table->id('id_payroll_periods');
            $table->unsignedBigInteger('id_companies');
            $table->string('name', 100);
            $table->date('start_date');
            $table->date('end_date');
            $table->date('payment_date');
            $table->enum('status', ['draft', 'calculated', 'finalized', 'paid'])->default('draft');
            $table->timestamps();

            $table->foreign('id_companies')
                ->references('id_companies')
                ->on('companies')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payroll_periods');
    }
};
