<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('branches', function (Blueprint $table) {
            $table->id('id_branches');
            $table->unsignedBigInteger('id_companies');
            $table->string('name', 100);
            $table->text('address');
            $table->decimal('latitude', 10, 8);
            $table->decimal('longitude', 11, 8);
            $table->unsignedInteger('radius_meters')->default(50);
            $table->timestamps();

            $table->foreign('id_companies')
                ->references('id_companies')
                ->on('companies')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('branches');
    }
};
