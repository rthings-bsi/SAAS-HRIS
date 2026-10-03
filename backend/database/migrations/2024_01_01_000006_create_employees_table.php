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
            $table->unsignedBigInteger('id_branches')->nullable();
            $table->unsignedBigInteger('id_departments')->nullable();
            $table->unsignedBigInteger('id_job_positions')->nullable();
            $table->string('nik', 50);
            $table->string('phone', 30)->nullable();
            $table->enum('gender', ['male', 'female']);
            $table->date('birth_date')->nullable();
            $table->date('hire_date');
            $table->enum('employment_status', ['permanent', 'contract', 'probation', 'intern'])->default('contract');
            $table->decimal('basic_salary', 14, 2)->default(0);
            $table->decimal('allowance_fixed', 14, 2)->default(0);
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

            $table->foreign('id_branches')
                ->references('id_branches')
                ->on('branches')
                ->onDelete('set null');

            $table->foreign('id_departments')
                ->references('id_departments')
                ->on('departments')
                ->onDelete('set null');

            $table->foreign('id_job_positions')
                ->references('id_job_positions')
                ->on('job_positions')
                ->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('employees');
    }
};
