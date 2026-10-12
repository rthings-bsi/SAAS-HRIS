<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('companies', function (Blueprint $table) {
            $table->id('id_companies');
            $table->string('name', 150);
            $table->string('industry', 150)->nullable();
            $table->string('email', 150);
            $table->string('website', 150)->nullable();
            $table->string('phone', 30)->nullable();
            $table->text('address')->nullable();
            $table->string('director_name', 150)->nullable();
            $table->string('hr_manager_name', 150)->nullable();
            $table->string('logo_url', 255)->nullable();
            $table->decimal('latitude', 10, 8)->nullable()->default(-6.20000000);
            $table->decimal('longitude', 11, 8)->nullable()->default(106.81666600);
            $table->unsignedInteger('radius_meters')->default(100);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('companies');
    }
};
