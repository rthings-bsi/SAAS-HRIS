<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('leave_types', function (Blueprint $table) {
            $table->id('id_leave_types');
            $table->unsignedBigInteger('id_companies');
            $table->string('name', 100);
            $table->unsignedInteger('quota_days')->default(12);
            $table->boolean('is_paid')->default(true);
            $table->timestamps();

            $table->foreign('id_companies')
                ->references('id_companies')
                ->on('companies')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('leave_types');
    }
};
