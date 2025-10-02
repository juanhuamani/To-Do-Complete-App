# 🚀 To-Do Complete App - Backend API

Backend API desarrollado con **Laravel 12** para la aplicación de gestión de tareas To-Do Complete.

## 🏗️ Características

### 🔧 Tecnologías
- **Laravel 12** - Framework PHP moderno
- **Laravel Sanctum** - Autenticación API
- **MySQL 8** - Base de datos relacional
- **PHP 8.2+** - Lenguaje de programación
- **Eloquent ORM** - Mapeo objeto-relacional

### 🎯 Funcionalidades
- **API RESTful** completa para gestión de tareas
- **CRUD completo** (Create, Read, Update, Delete)
- **Reordenamiento** de tareas con drag & drop
- **Filtros avanzados** por estado, prioridad y búsqueda
- **Validación robusta** de datos
- **Respuestas JSON** estructuradas

## 🚀 Instalación

### Instalación Local
```bash
# Instalar dependencias
composer install

# Configurar entorno
cp .env.example .env
php artisan key:generate

# Configurar base de datos en .env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=todo_app
DB_USERNAME=tu_usuario
DB_PASSWORD=tu_password

# Ejecutar migraciones
php artisan migrate

# Poblar base de datos (opcional)
php artisan db:seed

# Iniciar servidor
php artisan serve
```

### Instalación con Docker
```bash
docker build -t todo-complete-backend:local .
docker run -p 8000:8000 todo-complete-backend:local
```

### Instalación con Kubernetes
```bash
# Desplegar en Minikube
bash ../scripts/minikube-deploy.sh

# Herramientas de desarrollo
bash ../scripts/dev-tools.sh start-ports
```

## 📖 API Documentation

### Base URL
```
http://localhost:8000/api
```

### Endpoints Principales
```http
GET    /api/tasks              # Obtener todas las tareas
POST   /api/tasks              # Crear nueva tarea
GET    /api/tasks/{id}         # Obtener tarea específica
PUT    /api/tasks/{id}         # Actualizar tarea
DELETE /api/tasks/{id}         # Eliminar tarea
POST   /api/tasks/reorder      # Reordenar tareas
GET    /api/tasks/status/{status} # Filtrar por estado
```

### Ejemplo de Uso
```bash
# Crear tarea
curl -X POST http://localhost:8000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Implementar autenticación",
    "description": "Agregar sistema de login",
    "status": "todo",
    "priority": "high",
    "assignee": "Juan Pérez",
    "tags": ["backend", "security"]
  }'

# Obtener tareas
curl http://localhost:8000/api/tasks
```

## 🗄️ Base de Datos

### Estructura de la Tabla `tasks`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | bigint | ID único |
| `content` | string | Título |
| `description` | text | Descripción |
| `status` | enum | Estado (todo, in-progress, completed, archived) |
| `priority` | enum | Prioridad (low, medium, high) |
| `assignee` | string | Responsable |
| `due_date` | date | Fecha de vencimiento |
| `tags` | json | Etiquetas |
| `order` | int | Orden |

### Comandos Útiles
```bash
# Migraciones
php artisan migrate
php artisan migrate:fresh --seed

# Seeders
php artisan db:seed --class=TaskSeeder

# Cache
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

## 🧪 Testing
```bash
# Ejecutar tests
php artisan test

# Tests con cobertura
php artisan test --coverage
```

## 🔧 Comandos Artisan
```bash
# Desarrollo
php artisan serve
php artisan tinker

# Crear componentes
php artisan make:controller TaskController --api
php artisan make:model Task -m

# Optimización
php artisan optimize
php artisan config:cache
```

## 📊 Monitoreo
```bash
# Logs
tail -f storage/logs/laravel.log

# Con Docker
docker logs -f <container_id>

# Con Kubernetes
kubectl logs -f deployment/backend
```

## 🔐 Seguridad
- **CORS** configurado
- **Validación** robusta
- **Sanitización** de datos
- **Rate limiting**
- **Headers de seguridad**

## 🤝 Contribución
1. Fork del repositorio
2. Crear rama feature
3. Commit con Conventional Commits
4. Push y crear Pull Request

## 📝 Licencia
MIT License - Ver `LICENSE` para más detalles.

---

**¡Desarrollado con ❤️ usando Laravel!** 🚀
