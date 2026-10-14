<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            if (!Schema::hasColumn('companies', 'role_configurations')) {
                $table->json('role_configurations')->nullable()->after('radius_meters');
            }
        });

        Schema::table('users', function (Blueprint $table) {
            $table->string('role', 50)->default('employee')->change();
        });
    }

    public function down(): void
    {
        Schema::table('companies', function (Blueprint $table) {
            if (Schema::hasColumn('companies', 'role_configurations')) {
                $table->dropColumn('role_configurations');
            }
        });

        Schema::table('users', function (Blueprint $table) {
            $table->enum('role', ['superadmin', 'owner', 'hr', 'manager', 'employee'])->default('employee')->change();
        });
    }
};
