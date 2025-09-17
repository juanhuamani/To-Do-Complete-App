<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TaskController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('/hello', function () {
    return response()->json(['message' => 'Hola desde Laravel API']);
});

// Rutas de la API para tareas
Route::apiResource('tasks', TaskController::class);

// Rutas adicionales para funcionalidades específicas
Route::post('/tasks/reorder', [TaskController::class, 'reorder']);
Route::get('/tasks/status/{status}', [TaskController::class, 'getByStatus']);
