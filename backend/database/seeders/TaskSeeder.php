<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Task;

class TaskSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $tasks = [
            [
                'content' => 'Diseñar la interfaz futurista',
                'description' => 'Crear un diseño moderno y atractivo para la aplicación',
                'status' => 'in-progress',
                'priority' => 'high',
                'assignee' => 'Juan Pérez',
                'due_date' => now()->addDays(7),
                'tags' => ['frontend', 'diseño', 'ux'],
                'order' => 1
            ],
            [
                'content' => 'Implementar drag and drop',
                'description' => 'Integrar funcionalidad de arrastrar y soltar con @hello-pangea/dnd',
                'status' => 'completed',
                'priority' => 'medium',
                'assignee' => 'María García',
                'due_date' => now()->subDays(2),
                'tags' => ['frontend', 'funcionalidad', 'react'],
                'order' => 1
            ],
            [
                'content' => 'Agregar animaciones fluidas',
                'description' => 'Mejorar la experiencia de usuario con transiciones suaves',
                'status' => 'todo',
                'priority' => 'low',
                'assignee' => null,
                'due_date' => now()->addDays(14),
                'tags' => ['ux', 'animaciones', 'css'],
                'order' => 2
            ],
            [
                'content' => 'Optimizar rendimiento',
                'description' => 'Mejorar la velocidad de carga y optimizar el bundle',
                'status' => 'todo',
                'priority' => 'high',
                'assignee' => 'Carlos López',
                'due_date' => now()->addDays(10),
                'tags' => ['performance', 'optimización', 'webpack'],
                'order' => 3
            ],
            [
                'content' => 'Documentar código',
                'description' => 'Crear documentación técnica completa del proyecto',
                'status' => 'archived',
                'priority' => 'low',
                'assignee' => null,
                'due_date' => now()->subDays(5),
                'tags' => ['documentación', 'markdown'],
                'order' => 1
            ],
            [
                'content' => 'Configurar CI/CD',
                'description' => 'Implementar pipeline de integración y despliegue continuo',
                'status' => 'in-progress',
                'priority' => 'medium',
                'assignee' => 'Ana Martínez',
                'due_date' => now()->addDays(5),
                'tags' => ['devops', 'github-actions', 'deployment'],
                'order' => 2
            ],
            [
                'content' => 'Implementar tests unitarios',
                'description' => 'Crear suite de pruebas para componentes React',
                'status' => 'todo',
                'priority' => 'medium',
                'assignee' => 'Pedro Sánchez',
                'due_date' => now()->addDays(12),
                'tags' => ['testing', 'jest', 'react-testing-library'],
                'order' => 4
            ],
            [
                'content' => 'Optimizar base de datos',
                'description' => 'Crear índices y optimizar consultas SQL',
                'status' => 'todo',
                'priority' => 'high',
                'assignee' => 'Laura Ruiz',
                'due_date' => now()->addDays(8),
                'tags' => ['database', 'mysql', 'optimización'],
                'order' => 5
            ]
        ];

        foreach ($tasks as $taskData) {
            Task::create($taskData);
        }
    }
}
