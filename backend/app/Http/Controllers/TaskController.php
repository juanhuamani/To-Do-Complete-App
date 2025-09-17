<?php

namespace App\Http\Controllers;

use App\Models\Task;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\Rule;

class TaskController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Task::query();

        // Filtros opcionales
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('priority')) {
            $query->where('priority', $request->priority);
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('content', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        // Ordenar por order y luego por fecha de creación
        $tasks = $query->orderBy('order')->orderBy('created_at', 'desc')->get();

        return response()->json($tasks);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'content' => 'required|string|max:255',
            'description' => 'nullable|string',
            'status' => ['required', Rule::in(['todo', 'in-progress', 'completed', 'archived'])],
            'priority' => ['required', Rule::in(['low', 'medium', 'high'])],
            'assignee' => 'nullable|string|max:255',
            'due_date' => 'nullable|date',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:50'
        ]);

        // Obtener el siguiente order para el status
        $maxOrder = Task::where('status', $validated['status'])->max('order');
        $validated['order'] = ($maxOrder ?? 0) + 1;

        $task = Task::create($validated);

        return response()->json($task, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Task $task): JsonResponse
    {
        return response()->json($task);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Task $task): JsonResponse
    {
        $validated = $request->validate([
            'content' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'status' => ['sometimes', Rule::in(['todo', 'in-progress', 'completed', 'archived'])],
            'priority' => ['sometimes', Rule::in(['low', 'medium', 'high'])],
            'assignee' => 'nullable|string|max:255',
            'due_date' => 'nullable|date',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:50'
        ]);

        $task->update($validated);

        return response()->json($task);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Task $task): JsonResponse
    {
        $task->delete();

        return response()->json(['message' => 'Tarea eliminada correctamente']);
    }

    /**
     * Reordenar tareas (drag and drop)
     */
    public function reorder(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'tasks' => 'required|array',
            'tasks.*.id' => 'required|exists:tasks,id',
            'tasks.*.order' => 'required|integer|min:0',
            'tasks.*.status' => ['required', Rule::in(['todo', 'in-progress', 'completed', 'archived'])]
        ]);

        foreach ($validated['tasks'] as $taskData) {
            Task::where('id', $taskData['id'])->update([
                'order' => $taskData['order'],
                'status' => $taskData['status']
            ]);
        }

        return response()->json(['message' => 'Tareas reordenadas correctamente']);
    }

    /**
     * Obtener tareas por estado
     */
    public function getByStatus(string $status): JsonResponse
    {
        $validStatuses = ['todo', 'in-progress', 'completed', 'archived'];
        
        if (!in_array($status, $validStatuses)) {
            return response()->json(['error' => 'Estado inválido'], 400);
        }

        $tasks = Task::where('status', $status)
                    ->orderBy('order')
                    ->orderBy('created_at', 'desc')
                    ->get();

        return response()->json($tasks);
    }
}
