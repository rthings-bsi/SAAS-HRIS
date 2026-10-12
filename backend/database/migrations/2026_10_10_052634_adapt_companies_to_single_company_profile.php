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
        if (Schema::hasColumn('companies', 'slug')) {
            try {
                \Illuminate\Support\Facades\DB::statement('DROP INDEX IF EXISTS companies_slug_unique');
            } catch (\Throwable) {
                // Ignore if driver does not support or index missing
            }
        }

        Schema::table('companies', function (Blueprint $table) {
            if (Schema::hasColumn('companies', 'subscription_status')) {
                $table->dropColumn('subscription_status');
            }
            if (Schema::hasColumn('companies', 'trial_ends_at')) {
                $table->dropColumn('trial_ends_at');
            }
            if (Schema::hasColumn('companies', 'slug')) {
                $table->dropColumn('slug');
            }
            if (!Schema::hasColumn('companies', 'industry')) {
                $table->string('industry')->nullable()->after('name');
            }
            if (!Schema::hasColumn('companies', 'website')) {
                $table->string('website')->nullable()->after('email');
            }
            if (!Schema::hasColumn('companies', 'director_name')) {
                $table->string('director_name')->nullable()->after('address');
            }
            if (!Schema::hasColumn('companies', 'hr_manager_name')) {
                $table->string('hr_manager_name')->nullable()->after('director_name');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            $table->dropColumn(['industry', 'website', 'director_name', 'hr_manager_name']);
            $table->string('slug')->nullable();
            $table->string('subscription_status')->default('active');
            $table->timestamp('trial_ends_at')->nullable();
        });
    }
};
