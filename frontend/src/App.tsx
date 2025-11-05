import { useState, useEffect } from 'react'
import { BrowserRouter as Router, Routes, Route, useNavigate } from 'react-router-dom'
import type { DropResult } from '@hello-pangea/dnd'
import { Search, X, Clock, Play, CheckSquare, Archive } from 'lucide-react'
import Header from './components/Header'
import KanbanBoard from './components/KanbanBoard'
import CreateTask from './components/CreateTask'
import MetricsPanel from './components/MetricsPanel'
import { apiService, type CreateTaskData } from './services/api'
import './App.css'

interface Task {
  id: number
  content: string
  status: 'todo' | 'in-progress' | 'completed' | 'archived'
  priority: 'low' | 'medium' | 'high'
  created_at: string
  description?: string
  assignee?: string
  due_date?: string
  tags?: string[]
  order: number
}

const columns = {
  todo: {
    id: 'todo',
    title: 'Pendientes',
    icon: Clock,
    color: 'text-blue-400',
    bgColor: 'bg-blue-500/10',
    borderColor: 'border-blue-400/30'
  },
  'in-progress': {
    id: 'in-progress',
    title: 'En Progreso',
    icon: Play,
    color: 'text-yellow-400',
    bgColor: 'bg-yellow-500/10',
    borderColor: 'border-yellow-400/30'
  },
  completed: {
    id: 'completed',
    title: 'Completadas',
    icon: CheckSquare,
    color: 'text-green-400',
    bgColor: 'bg-green-500/10',
    borderColor: 'border-green-400/30'
  },
  archived: {
    id: 'archived',
    title: 'Archivadas',
    icon: Archive,
    color: 'text-purple-400',
    bgColor: 'bg-purple-500/10',
    borderColor: 'border-purple-400/30'
  }
}


// Componente principal del tablero
function KanbanPage() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [, setLoading] = useState(true)
  const [, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [priorityFilter, setPriorityFilter] = useState<string>('all')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const navigate = useNavigate()

  // Cargar tareas desde la API
  useEffect(() => {
    loadTasks()
  }, [])

  const loadTasks = async () => {
    try {
      setLoading(true)
      setError(null)
      const apiTasks = await apiService.getTasks()
      setTasks(apiTasks)
    } catch (err) {
      setError('Error al cargar las tareas')
      console.error('Error loading tasks:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleDragEnd = async (result: DropResult) => {
    if (!result.destination) return

    const { source, destination } = result

    // Actualizar estado local inmediatamente para mejor UX
    const newTasks = [...tasks]
    
    if (source.droppableId === destination.droppableId) {
      // Mismo dentro de la misma columna
      const columnTasks = newTasks.filter(task => task.status === source.droppableId)
      const otherTasks = newTasks.filter(task => task.status !== source.droppableId)
      
      const [reorderedItem] = columnTasks.splice(source.index, 1)
      reorderedItem.order = destination.index + 1
      columnTasks.splice(destination.index, 0, reorderedItem)
      
      // Actualizar orders
      columnTasks.forEach((task, index) => {
        task.order = index + 1
      })
      
      setTasks([...otherTasks, ...columnTasks])
    } else {
      // Mover entre columnas diferentes
      const sourceTasks = newTasks.filter(task => task.status === source.droppableId)
      const destTasks = newTasks.filter(task => task.status === destination.droppableId)
      const otherTasks = newTasks.filter(task => 
        task.status !== source.droppableId && task.status !== destination.droppableId
      )

      const [movedTask] = sourceTasks.splice(source.index, 1)
      movedTask.status = destination.droppableId as Task['status']
      movedTask.order = destination.index + 1
      
      destTasks.splice(destination.index, 0, movedTask)
      
      // Actualizar orders
      sourceTasks.forEach((task, index) => {
        task.order = index + 1
      })
      destTasks.forEach((task, index) => {
        task.order = index + 1
      })
      
      setTasks([...otherTasks, ...sourceTasks, ...destTasks])
    }

    // Enviar cambios a la API
    try {
      const tasksToReorder = newTasks.map(task => ({
        id: task.id,
        order: task.order,
        status: task.status
      }))
      
      await apiService.reorderTasks(tasksToReorder)
    } catch (err) {
      console.error('Error reordering tasks:', err)
      // Recargar tareas en caso de error
      loadTasks()
    }
  }

  const deleteTask = async (id: number) => {
    try {
      await apiService.deleteTask(id)
      setTasks(tasks.filter(task => task.id !== id))
    } catch (err) {
      console.error('Error deleting task:', err)
      setError('Error al eliminar la tarea')
    }
  }


  const getFilteredTasks = () => {
    return tasks.filter(task => {
      const matchesSearch = task.content.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           (task.description && task.description.toLowerCase().includes(searchTerm.toLowerCase()))
      const matchesPriority = priorityFilter === 'all' || task.priority === priorityFilter
      const matchesStatus = statusFilter === 'all' || task.status === statusFilter
      
      return matchesSearch && matchesPriority && matchesStatus
    })
  }

  const clearFilters = () => {
    setSearchTerm('')
    setPriorityFilter('all')
    setStatusFilter('all')
  }

  const getFilteredTasksByStatus = (status: keyof typeof columns) => {
    const filteredTasks = getFilteredTasks()
    return filteredTasks.filter(task => task.status === status)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      {/* Efectos de fondo */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-purple-500 rounded-full mix-blend-multiply filter blur-xl opacity-20"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-cyan-500 rounded-full mix-blend-multiply filter blur-xl opacity-20"></div>
      </div>

      <div className="relative z-10 flex flex-col h-screen">
        <Header onAddTaskClick={() => navigate('/create-task')} />

        {/* Filtros */}
        <div className="px-6 py-4 border-b border-slate-700/50 backdrop-blur-sm bg-slate-900/20">
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <Search className="w-4 h-4 text-gray-400" />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Buscar tareas..."
                className="px-3 py-2 bg-slate-800/70 border border-slate-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-cyan-400 w-48 text-sm"
              />
            </div>

            <select
              value={priorityFilter}
              onChange={(e) => setPriorityFilter(e.target.value)}
              className="px-3 py-2 bg-slate-800/70 border border-slate-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-cyan-400 text-sm"
            >
              <option value="all">Todas las prioridades</option>
              <option value="high">Alta prioridad</option>
              <option value="medium">Media prioridad</option>
              <option value="low">Baja prioridad</option>
            </select>

            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-3 py-2 bg-slate-800/70 border border-slate-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-cyan-400 text-sm"
            >
              <option value="all">Todos los estados</option>
              <option value="todo">Pendientes</option>
              <option value="in-progress">En Progreso</option>
              <option value="completed">Completadas</option>
              <option value="archived">Archivadas</option>
            </select>

            {(searchTerm || priorityFilter !== 'all' || statusFilter !== 'all') && (
              <button
                onClick={clearFilters}
                className="flex items-center gap-2 px-3 py-2 text-gray-400 hover:text-white smooth-transition text-sm"
              >
                <X className="w-4 h-4" />
                Limpiar filtros
              </button>
            )}
          </div>
        </div>

        {/* Tablero Kanban */}
        <KanbanBoard 
          tasks={getFilteredTasks()}
          onTaskReorder={handleDragEnd}
          onTaskDelete={deleteTask}
        />

        {/* Estadísticas */}
        <div className="p-6 border-t border-slate-700/50 backdrop-blur-sm bg-slate-900/30">
          <div className="flex justify-center gap-8">
            {Object.entries(columns).map(([key, column]) => {
              const count = getFilteredTasksByStatus(key as keyof typeof columns).length
              return (
                <div key={key} className="text-center">
                  <div className={`text-2xl font-bold ${column.color}`}>{count}</div>
                  <div className="text-sm text-gray-400">{column.title}</div>
                </div>
              )
            })}
            <div className="text-center">
              <div className="text-2xl font-bold text-cyan-400">{getFilteredTasks().length}</div>
              <div className="text-sm text-gray-400">
                {getFilteredTasks().length === tasks.length ? 'Total' : 'Filtradas'}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Panel de métricas */}
      <MetricsPanel />
    </div>
  )
}

// Componente principal de la aplicación
function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<KanbanPage />} />
        <Route path="/create-task" element={<CreateTaskWrapper />} />
      </Routes>
    </Router>
  )
}

// Wrapper para pasar la función addTask
function CreateTaskWrapper() {
  const handleTaskCreated = async (taskData: CreateTaskData) => {
    try {
      await apiService.createTask(taskData)
      // La navegación se maneja en el componente CreateTask
    } catch (err) {
      console.error('Error creating task:', err)
      throw err // Re-throw para que CreateTask pueda manejar el error
    }
  }

  return <CreateTask onTaskCreated={handleTaskCreated} />
}

export default App
