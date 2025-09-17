import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd'
import type { DropResult } from '@hello-pangea/dnd'
import { Trash2, GripVertical, Clock, Play, CheckSquare, Archive } from 'lucide-react'

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

interface KanbanBoardProps {
  tasks: Task[]
  onTaskReorder: (result: DropResult) => void
  onTaskDelete: (id: number) => void
}

export default function KanbanBoard({ tasks, onTaskReorder, onTaskDelete }: KanbanBoardProps) {
  const getFilteredTasksByStatus = (status: keyof typeof columns) => {
    return tasks.filter(task => task.status === status)
  }

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return 'text-red-400 border-red-400'
      case 'medium': return 'text-yellow-400 border-yellow-400'
      case 'low': return 'text-green-400 border-green-400'
      default: return 'text-blue-400 border-blue-400'
    }
  }

  const getPriorityIcon = (priority: string) => {
    switch (priority) {
      case 'high': return '🔴'
      case 'medium': return '🟡'
      case 'low': return '🟢'
      default: return '🔵'
    }
  }

  return (
    <div className="flex-1 p-6 overflow-hidden">
      <DragDropContext onDragEnd={onTaskReorder}>
        <div className="flex gap-6 h-full overflow-x-auto kanban-container">
          {Object.entries(columns).map(([columnKey, column]) => {
            const columnTasks = getFilteredTasksByStatus(columnKey as keyof typeof columns)
            const IconComponent = column.icon

            return (
              <div key={columnKey} className="flex-shrink-0 w-80">
                {/* Header de la columna */}
                <div className={`flex items-center gap-3 p-4 rounded-t-xl border ${column.borderColor} ${column.bgColor} backdrop-blur-sm`}>
                  <IconComponent className={`w-5 h-5 ${column.color}`} />
                  <h3 className={`font-semibold ${column.color}`}>{column.title}</h3>
                  <span className="ml-auto text-sm text-gray-400 bg-slate-700/50 px-2 py-1 rounded-full">
                    {columnTasks.length}
                  </span>
                </div>

                {/* Lista de tareas */}
                <Droppable droppableId={columnKey}>
                  {(provided, snapshot) => (
                    <div
                      ref={provided.innerRef}
                      {...provided.droppableProps}
                      className={`min-h-[500px] p-4 rounded-b-xl transition-all duration-300 ${
                        snapshot.isDraggingOver 
                          ? 'bg-slate-800/50 border-2 border-dashed border-cyan-400/50' 
                          : 'bg-slate-800/20 border border-slate-700/50'
                      }`}
                      style={{
                        minHeight: '500px !important',
                      }}
                    >
                      <div className="space-y-3">
                        {columnTasks.length === 0 ? (
                          <div className="text-center py-12 text-gray-500">
                            <IconComponent className="w-12 h-12 mx-auto mb-3 opacity-50" />
                            <p>No hay tareas</p>
                          </div>
                        ) : (
                          columnTasks.map((task, index) => (
                            <Draggable key={task.id} draggableId={task.id.toString()} index={index}>
                              {(provided, snapshot) => (
                                <div
                                  ref={provided.innerRef}
                                  {...provided.draggableProps}
                                  className={`group relative p-4 rounded-xl smooth-transition ${
                                    snapshot.isDragging
                                      ? 'bg-slate-700/80 shadow-lg shadow-purple-500/25 transform rotate-1 scale-102'
                                      : 'bg-slate-800/50 hover:bg-slate-700/70 hover:shadow-md hover:shadow-cyan-500/10'
                                  }`}
                                >
                                  <div className="relative">
                                    {/* Handle de arrastre */}
                                    <div
                                      {...provided.dragHandleProps}
                                      className="absolute -top-2 -left-2 text-gray-400 hover:text-cyan-400 smooth-transition cursor-grab active:cursor-grabbing opacity-0 group-hover:opacity-100"
                                    >
                                      <GripVertical className="w-4 h-4" />
                                    </div>

                                    {/* Contenido de la tarea */}
                                    <div className="mb-3">
                                      <h4 className="text-white font-medium mb-1 line-clamp-2">
                                        {task.content}
                                      </h4>
                                      {task.description && (
                                        <p className="text-gray-400 text-sm line-clamp-2">
                                          {task.description}
                                        </p>
                                      )}
                                    </div>

                                    {/* Información adicional */}
                                    {(task.assignee || task.due_date || task.tags?.length) && (
                                      <div className="mb-3 space-y-1">
                                        {task.assignee && (
                                          <div className="flex items-center gap-1 text-xs text-gray-400">
                                            <span>👤</span>
                                            <span>{task.assignee}</span>
                                          </div>
                                        )}
                                        {task.due_date && (
                                          <div className="flex items-center gap-1 text-xs text-gray-400">
                                            <span>📅</span>
                                            <span>{new Date(task.due_date).toLocaleDateString()}</span>
                                          </div>
                                        )}
                                        {task.tags && task.tags.length > 0 && (
                                          <div className="flex items-center gap-1 text-xs text-gray-400">
                                            <span>🏷️</span>
                                            <span>{task.tags.join(', ')}</span>
                                          </div>
                                        )}
                                      </div>
                                    )}

                                    {/* Footer de la tarea */}
                                    <div className="flex items-center justify-between">
                                      <div className="flex items-center gap-2">
                                        <span className={`text-xs px-2 py-1 rounded-full border ${getPriorityColor(task.priority)}`}>
                                          {task.priority.toUpperCase()}
                                        </span>
                                        <span className="text-xs text-gray-500">
                                          {getPriorityIcon(task.priority)}
                                        </span>
                                      </div>
                                      
                                          <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 smooth-transition">
                                            <span className="text-xs text-gray-500">
                                              {new Date(task.created_at).toLocaleDateString()}
                                            </span>
                                        <button
                                          onClick={() => onTaskDelete(task.id)}
                                          className="text-gray-400 hover:text-red-400 smooth-transition p-1 hover:bg-red-500/10 rounded"
                                        >
                                          <Trash2 className="w-3 h-3" />
                                        </button>
                                      </div>
                                    </div>
                                  </div>
                                </div>
                              )}
                            </Draggable>
                          ))
                        )}
                      </div>
                      {provided.placeholder}
                    </div>
                  )}
                </Droppable>
              </div>
            )
          })}
        </div>
      </DragDropContext>
    </div>
  )
}
