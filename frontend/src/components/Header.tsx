import { Plus } from 'lucide-react'

interface HeaderProps {
  onAddTaskClick: () => void
}

export default function Header({ onAddTaskClick }: HeaderProps) {
  return (
    <div className="p-6 border-b border-slate-700/50 backdrop-blur-sm bg-slate-900/30">
      {/* Título y descripción */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-3">
            <svg className="w-8 h-8 text-cyan-400" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z" clipRule="evenodd" />
            </svg>
            <h1 className="text-3xl font-bold text-gradient">
              TaskFlow
            </h1>
          </div>
          <p className="text-gray-300">Sistema de gestión de tareas</p>
        </div>
        
        {/* Botón para crear tarea */}
        <button
          onClick={onAddTaskClick}
          className="px-4 py-2 bg-gradient-to-r from-cyan-500 to-purple-500 text-white rounded-lg hover:from-cyan-600 hover:to-purple-600 smooth-transition flex items-center gap-2 text-sm"
        >
          <Plus className="w-4 h-4" />
          Nueva Tarea
        </button>
      </div>
    </div>
  )
}
