const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://backend:8000/api'

export interface Task {
  id: number
  content: string
  description?: string
  status: 'todo' | 'in-progress' | 'completed' | 'archived'
  priority: 'low' | 'medium' | 'high'
  assignee?: string
  due_date?: string
  tags?: string[]
  order: number
  created_at: string
  updated_at: string
}

export interface CreateTaskData {
  content: string
  description?: string
  status: 'todo' | 'in-progress' | 'completed' | 'archived'
  priority: 'low' | 'medium' | 'high'
  assignee?: string
  due_date?: string
  tags?: string[]
}

export interface UpdateTaskData extends Partial<CreateTaskData> {}

export interface ReorderTaskData {
  id: number
  order: number
  status: 'todo' | 'in-progress' | 'completed' | 'archived'
}

class ApiService {
  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${API_BASE_URL}${endpoint}`
    
    const config: RequestInit = {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    }

    try {
      const response = await fetch(url, config)
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      return await response.json()
    } catch (error) {
      console.error('API request failed:', error)
      throw error
    }
  }

  // Obtener todas las tareas
  async getTasks(filters?: {
    status?: string
    priority?: string
    search?: string
  }): Promise<Task[]> {
    const params = new URLSearchParams()
    
    if (filters?.status) params.append('status', filters.status)
    if (filters?.priority) params.append('priority', filters.priority)
    if (filters?.search) params.append('search', filters.search)
    
    const queryString = params.toString()
    const endpoint = queryString ? `/tasks?${queryString}` : '/tasks'
    
    return this.request<Task[]>(endpoint)
  }

  // Obtener tarea por ID
  async getTask(id: number): Promise<Task> {
    return this.request<Task>(`/tasks/${id}`)
  }

  // Crear nueva tarea
  async createTask(data: CreateTaskData): Promise<Task> {
    return this.request<Task>('/tasks', {
      method: 'POST',
      body: JSON.stringify(data),
    })
  }

  // Actualizar tarea
  async updateTask(id: number, data: UpdateTaskData): Promise<Task> {
    return this.request<Task>(`/tasks/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    })
  }

  // Eliminar tarea
  async deleteTask(id: number): Promise<{ message: string }> {
    return this.request<{ message: string }>(`/tasks/${id}`, {
      method: 'DELETE',
    })
  }

  // Reordenar tareas
  async reorderTasks(tasks: ReorderTaskData[]): Promise<{ message: string }> {
    return this.request<{ message: string }>('/tasks/reorder', {
      method: 'POST',
      body: JSON.stringify({ tasks }),
    })
  }

  // Obtener tareas por estado
  async getTasksByStatus(status: string): Promise<Task[]> {
    return this.request<Task[]>(`/tasks/status/${status}`)
  }
}

export const apiService = new ApiService()
