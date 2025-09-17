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
        Schema::create('tasks', function (Blueprint $table) {
            $table->id();
            $table->string('content');
            $table->text('description')->nullable();
            $table->enum('status', ['todo', 'in-progress', 'completed', 'archived'])->default('todo');
            $table->enum('priority', ['low', 'medium', 'high'])->default('medium');
            $table->string('assignee')->nullable();
            $table->date('due_date')->nullable();
            $table->json('tags')->nullable();
            $table->integer('order')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tasks');
    }
};
