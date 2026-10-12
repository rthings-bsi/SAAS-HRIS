<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('leave_requests', function (Blueprint $table) {
            $table->id('id_leave_requests');
            $table->unsignedBigInteger('id_companies');
            $table->unsignedBigInteger('id_employees');
            $table->string('leave_type', 50)->default('Cuti Tahunan');
            $table->boolean('is_paid')->default(true);
            $table->date('start_date');
            $table->date('end_date');
            $table->unsignedInteger('total_days');
            $table->text('reason');
            $table->string('attachment_url', 255)->nullable();
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->unsignedBigInteger('approved_by')->nullable();
            $table->text('rejected_reason')->nullable();
            $table->timestamps();

            $table->foreign('id_companies')
                ->references('id_companies')
                ->on('companies')
                ->onDelete('cascade');

            $table->foreign('id_employees')
                ->references('id_employees')
                ->on('employees')
                ->onDelete('cascade');

            $table->foreign('approved_by')
                ->references('id_users')
                ->on('users')
                ->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('leave_requests');
    }
};
