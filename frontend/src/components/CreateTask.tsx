import { useState } from 'react'
import { ArrowLeft, Save, User, Tag, FileText } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { type CreateTaskData } from '../services/api'

interface CreateTaskProps {
  onTaskCreated: (task: CreateTaskData) => Promise<void>
}

export default function CreateTask({ onTaskCreated }: CreateTaskProps) {
  const navigate = useNavigate()
  const [formData, setFormData] = useState({
    content: '',
    description: '',
    status: 'todo' as CreateTaskData['status'],
    priority: 'medium' as CreateTaskData['priority'],
    assignee: '',
    due_date: '',
    tags: ''
  })

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!formData.content.trim()) {
      alert('El título de la tarea es obligatorio')
      return
    }

    try {
      const newTask: CreateTaskData = {
        content: formData.content.trim(),
        description: formData.description.trim() || undefined,
        status: formData.status,
        priority: formData.priority,
        assignee: formData.assignee.trim() || undefined,
        due_date: formData.due_date || undefined,
        tags: formData.tags.split(',').map(tag => tag.trim()).filter(tag => tag.length > 0)
      }

      await onTaskCreated(newTask)
      navigate('/')
    } catch (error) {
      console.error('Error creating task:', error)
      alert('Error al crear la tarea. Por favor, inténtalo de nuevo.')
    }
  }

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return 'text-red-400'
      case 'medium': return 'text-yellow-400'
      case 'low': return 'text-green-400'
      default: return 'text-blue-400'
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      {/* Efectos de fondo */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-purple-500 rounded-full mix-blend-multiply filter blur-xl opacity-20"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-cyan-500 rounded-full mix-blend-multiply filter blur-xl opacity-20"></div>
      </div>

      <div className="relative z-10 flex flex-col h-screen">
        {/* Header */}
        <div className="p-6 border-b border-slate-700/50 backdrop-blur-sm bg-slate-900/30">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <button
                onClick={() => navigate('/')}
                className="flex items-center gap-2 text-gray-400 hover:text-white smooth-transition"
              >
                <ArrowLeft className="w-5 h-5" />
                Volver al tablero
              </button>
              <div className="h-6 w-px bg-slate-600"></div>
              <h1 className="text-2xl font-bold text-gradient">Crear Nueva Tarea</h1>
            </div>
          </div>
        </div>

        {/* Formulario */}
        <div className="flex-1 p-6 overflow-y-auto">
          <div className="max-w-2xl mx-auto">
            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Información básica */}
              <div className="bg-slate-800/30 backdrop-blur-sm rounded-xl p-6 border border-slate-700/50">
                <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                  <FileText className="w-5 h-5 text-cyan-400" />
                  Información Básica
                </h2>
                
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Título de la tarea *
                    </label>
                    <input
                      type="text"
                      name="content"
                      value={formData.content}
                      onChange={handleInputChange}
                      placeholder="Ej: Implementar nueva funcionalidad"
                      className="w-full px-4 py-3 bg-slate-800/70 border border-slate-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-cyan-400"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Descripción
                    </label>
                    <textarea
                      name="description"
                      value={formData.description}
                      onChange={handleInputChange}
                      placeholder="Describe los detalles de la tarea..."
                      rows={4}
                      className="w-full px-4 py-3 bg-slate-800/70 border border-slate-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-cyan-400 resize-none"
                    />
                  </div>
                </div>
              </div>

              {/* Configuración de la tarea */}
              <div className="bg-slate-800/30 backdrop-blur-sm rounded-xl p-6 border border-slate-700/50">
                <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                  <Tag className="w-5 h-5 text-purple-400" />
                  Configuración
                </h2>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Estado inicial
                    </label>
                    <select
                      name="status"
                      value={formData.status}
                      onChange={handleInputChange}
                      className="w-full px-4 py-3 bg-slate-800/70 border border-slate-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-cyan-400"
                    >
                      <option value="todo">📋 Pendiente</option>
                      <option value="in-progress">⚡ En Progreso</option>
                      <option value="completed">✅ Completada</option>
                      <option value="archived">📁 Archivada</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Prioridad
                    </label>
                    <select
                      name="priority"
                      value={formData.priority}
                      onChange={handleInputChange}
                      className={`w-full px-4 py-3 bg-slate-800/70 border border-slate-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-cyan-400 ${getPriorityColor(formData.priority)}`}
                    >
                      <option value="low" className="text-green-400">🟢 Baja</option>
                      <option value="medium" className="text-yellow-400">🟡 Media</option>
                      <option value="high" className="text-red-400">🔴 Alta</option>
                    </select>
                  </div>
                </div>
              </div>

              {/* Información adicional */}
              <div className="bg-slate-800/30 backdrop-blur-sm rounded-xl p-6 border border-slate-700/50">
                <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                  <User className="w-5 h-5 text-green-400" />
                  Información Adicional
                </h2>
                
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Asignado a
                    </label>
                    <input
                      type="text"
                      name="assignee"
                      value={formData.assignee}
                      onChange={handleInputChange}
                      placeholder="Ej: Juan Pérez"
                      className="w-full px-4 py-3 bg-slate-800/70 border border-slate-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-cyan-400"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Fecha límite
                    </label>
                    <input
                      type="date"
                      name="dueDate"
                      value={formData.due_date}
                      onChange={handleInputChange}
                      className="w-full px-4 py-3 bg-slate-800/70 border border-slate-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-cyan-400"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Etiquetas
                    </label>
                    <input
                      type="text"
                      name="tags"
                      value={formData.tags}
                      onChange={handleInputChange}
                      placeholder="Ej: frontend, urgente, bug (separadas por comas)"
                      className="w-full px-4 py-3 bg-slate-800/70 border border-slate-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-cyan-400"
                    />
                  </div>
                </div>
              </div>

              {/* Botones de acción */}
              <div className="flex gap-4 justify-end">
                <button
                  type="button"
                  onClick={() => navigate('/')}
                  className="px-6 py-3 text-gray-400 hover:text-white smooth-transition"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="px-6 py-3 bg-gradient-to-r from-cyan-500 to-purple-500 text-white rounded-lg hover:from-cyan-600 hover:to-purple-600 smooth-transition flex items-center gap-2"
                >
                  <Save className="w-4 h-4" />
                  Crear Tarea
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  )
}
