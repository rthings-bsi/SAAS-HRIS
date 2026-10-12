<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('performance_periods', function (Blueprint $table) {
            $table->id('id_performance_periods');
            $table->string('name', 100);
            $table->date('start_date');
            $table->date('end_date');
            $table->enum('status', ['draft', 'active', 'calculated', 'finalized'])->default('draft');
            $table->json('criteria_config')->nullable();
            $table->timestamps();
        });

        Schema::create('performance_evaluations', function (Blueprint $table) {
            $table->id('id_performance_evaluations');
            $table->foreignId('id_performance_periods')
                ->constrained('performance_periods', 'id_performance_periods', 'pe_period_fk')
                ->onDelete('cascade');
            $table->foreignId('id_employees')
                ->constrained('employees', 'id_employees', 'pe_emp_fk')
                ->onDelete('cascade');
            $table->decimal('final_score', 6, 2)->nullable();
            $table->unsignedInteger('rank')->nullable();
            $table->string('grade', 50)->nullable();
            $table->string('recommendation', 255)->nullable();
            $table->text('notes')->nullable();
            $table->json('scores_breakdown')->nullable();
            $table->foreignId('evaluated_by')
                ->nullable()
                ->constrained('users', 'id_users', 'pe_evaluator_fk')
                ->nullOnDelete();
            $table->timestamps();

            $table->unique(['id_performance_periods', 'id_employees'], 'perf_eval_period_emp_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('performance_evaluations');
        Schema::dropIfExists('performance_periods');
    }
};
