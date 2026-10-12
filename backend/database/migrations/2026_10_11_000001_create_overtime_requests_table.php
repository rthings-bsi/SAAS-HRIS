<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('overtime_requests', function (Blueprint $table) {
            $table->id('id_overtime_requests');
            $table->unsignedBigInteger('id_companies');
            $table->unsignedBigInteger('id_employees');
            $table->date('date');
            $table->time('start_time');
            $table->time('end_time');
            $table->decimal('duration_hours', 5, 2);
            $table->text('reason');
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

            $table->index(['id_companies', 'status']);
            $table->index(['id_employees', 'date']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('overtime_requests');
    }
};
