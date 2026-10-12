<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('performance_criteria', function (Blueprint $table) {
            $table->id('id_performance_criteria');
            $table->string('code', 20)->unique();
            $table->string('name', 100);
            $table->enum('type', ['benefit', 'cost'])->default('benefit');
            $table->decimal('weight', 5, 2);
            $table->decimal('c_min', 8, 2)->default(0.00);
            $table->decimal('c_max', 8, 2)->default(100.00);
            $table->enum('source_type', ['manual', 'attendance'])->default('manual');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('performance_periods', function (Blueprint $table) {
            $table->id('id_performance_periods');
            $table->string('name', 100);
            $table->date('start_date');
            $table->date('end_date');
            $table->enum('status', ['draft', 'active', 'calculated', 'finalized'])->default('draft');
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
            $table->foreignId('evaluated_by')
                ->nullable()
                ->constrained('users', 'id_users', 'pe_evaluator_fk')
                ->nullOnDelete();
            $table->timestamps();

            $table->unique(['id_performance_periods', 'id_employees'], 'perf_eval_period_emp_unique');
        });

        Schema::create('performance_evaluation_details', function (Blueprint $table) {
            $table->id('id_performance_evaluation_details');
            $table->foreignId('id_performance_evaluations')
                ->constrained('performance_evaluations', 'id_performance_evaluations', 'ped_eval_fk')
                ->onDelete('cascade');
            $table->foreignId('id_performance_criteria')
                ->constrained('performance_criteria', 'id_performance_criteria', 'ped_crit_fk')
                ->onDelete('cascade');
            $table->decimal('raw_score', 8, 2)->default(0.00);
            $table->decimal('normalized_weight', 6, 4)->default(0.0000);
            $table->decimal('utility_score', 6, 2)->default(0.00);
            $table->decimal('weighted_score', 6, 2)->default(0.00);
            $table->timestamps();

            $table->unique(['id_performance_evaluations', 'id_performance_criteria'], 'perf_eval_crit_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('performance_evaluation_details');
        Schema::dropIfExists('performance_evaluations');
        Schema::dropIfExists('performance_periods');
        Schema::dropIfExists('performance_criteria');
    }
};
