<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('employees', function (Blueprint $table) {
            $table->id('id_employees');
            $table->unsignedBigInteger('id_companies');
            $table->unsignedBigInteger('id_users')->unique();
            $table->string('department_name', 100)->nullable();
            $table->string('job_position_name', 100)->nullable();
            $table->unsignedBigInteger('id_shifts')->nullable();
            $table->string('nik', 50);
            $table->string('phone', 30)->nullable();
            $table->enum('gender', ['male', 'female']);
            $table->date('birth_date')->nullable();
            $table->date('hire_date');
            $table->enum('employment_status', ['permanent', 'contract', 'probation', 'intern'])->default('contract');
            $table->decimal('basic_salary', 14, 2)->default(0);
            $table->decimal('allowance_fixed', 14, 2)->default(0);
            $table->unsignedInteger('annual_leave_quota')->default(12);
            $table->string('bank_name', 50)->nullable();
            $table->string('bank_account_number', 50)->nullable();
            $table->string('bank_account_holder', 100)->nullable();
            $table->timestamps();

            $table->foreign('id_companies')
                ->references('id_companies')
                ->on('companies')
                ->onDelete('cascade');

            $table->foreign('id_users')
                ->references('id_users')
                ->on('users')
                ->onDelete('cascade');

            $table->foreign('id_shifts')
                ->references('id_shifts')
                ->on('shifts')
                ->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('employees');
    }
};
