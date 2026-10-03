<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payroll_slips', function (Blueprint $table) {
            $table->id('id_payroll_slips');
            $table->unsignedBigInteger('id_companies');
            $table->unsignedBigInteger('id_payroll_periods');
            $table->unsignedBigInteger('id_employees');

            $table->decimal('basic_salary', 14, 2);
            $table->decimal('allowance_fixed', 14, 2)->default(0);
            $table->decimal('overtime_pay', 14, 2)->default(0);

            $table->decimal('deduction_late', 14, 2)->default(0);
            $table->decimal('deduction_absence', 14, 2)->default(0);
            $table->decimal('deduction_other', 14, 2)->default(0);

            $table->decimal('net_salary', 14, 2);
            $table->string('pdf_path', 255)->nullable();
            $table->timestamps();

            $table->unique(['id_payroll_periods', 'id_employees']);

            $table->foreign('id_companies')
                ->references('id_companies')
                ->on('companies')
                ->onDelete('cascade');

            $table->foreign('id_payroll_periods')
                ->references('id_payroll_periods')
                ->on('payroll_periods')
                ->onDelete('cascade');

            $table->foreign('id_employees')
                ->references('id_employees')
                ->on('employees')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payroll_slips');
    }
};
