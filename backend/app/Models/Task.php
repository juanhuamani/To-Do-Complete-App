<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Task extends Model
{
    use HasFactory;

    protected $fillable = [
        'content',
        'description',
        'status',
        'priority',
        'assignee',
        'due_date',
        'tags',
        'order'
    ];

    protected $casts = [
        'due_date' => 'date',
        'tags' => 'array',
        'order' => 'integer'
    ];

    protected $attributes = [
        'status' => 'todo',
        'priority' => 'medium',
        'order' => 0
    ];
}
