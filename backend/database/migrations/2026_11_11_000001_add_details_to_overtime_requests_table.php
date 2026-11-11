<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('overtime_requests', function (Blueprint $table) {
            $table->date('end_date')->nullable()->after('date');
            $table->string('overtime_type', 60)->nullable()->after('duration_hours');
            $table->string('reason_category', 80)->nullable()->after('overtime_type');
            $table->string('attachment_path', 255)->nullable()->after('reason');
        });
    }

    public function down(): void
    {
        Schema::table('overtime_requests', function (Blueprint $table) {
            $table->dropColumn([
                'end_date',
                'overtime_type',
                'reason_category',
                'attachment_path',
            ]);
        });
    }
};
