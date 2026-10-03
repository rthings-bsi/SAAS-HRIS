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
            $table->string('slug', 100)->unique();
            $table->string('email', 150);
            $table->string('phone', 30)->nullable();
            $table->text('address')->nullable();
            $table->string('logo_url', 255)->nullable();
            $table->enum('subscription_status', ['trial', 'active', 'suspended', 'cancelled'])->default('trial');
            $table->timestamp('trial_ends_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('companies');
    }
};
