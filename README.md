# 📋 To-Do Complete App

Una aplicación moderna de gestión de tareas construida con **Laravel** (backend) y **React + TypeScript** (frontend), diseñada para ofrecer una experiencia de usuario fluida y eficiente.

## ✨ Características

### 🎯 Funcionalidades Principales
- **Tablero Kanban Interactivo**: Organiza tus tareas en columnas (Pendientes, En Progreso, Completadas, Archivadas)
- **Drag & Drop**: Arrastra y suelta tareas entre columnas con animaciones fluidas
- **Gestión Completa de Tareas**: 
  - Título y descripción detallada
  - Prioridades (Baja, Media, Alta)
  - Asignación de responsables
  - Fechas de vencimiento
  - Sistema de etiquetas
- **Interfaz Moderna**: Diseño responsive con Tailwind CSS
- **API RESTful**: Backend robusto con Laravel Sanctum para autenticación

### 🚀 Tecnologías Utilizadas

#### Backend
- **Laravel 12** - Framework PHP moderno
- **Laravel Sanctum** - Autenticación API
- **MySQL 8** - Base de datos relacional
- **PHP 8.2+** - Lenguaje de programación

#### Frontend
- **React 19** - Biblioteca de interfaz de usuario
- **TypeScript** - Tipado estático para JavaScript
- **Tailwind CSS 4** - Framework de estilos utilitarios
- **React Router DOM** - Enrutamiento del lado del cliente
- **@hello-pangea/dnd** - Drag and drop para React
- **Lucide React** - Iconos modernos y consistentes
- **Vite** - Herramienta de construcción rápida

#### DevOps
- **Docker & Docker Compose** - Containerización
- **Kubernetes & Minikube** - Orquestación de contenedores
- **ESLint** - Linting de código
- **PHPUnit** - Testing del backend

## 🏗️ Arquitectura del Proyecto

```
To-Do-Complete-App/
├── backend/                 # API Laravel
│   ├── app/
│   │   ├── Http/Controllers/ # Controladores de la API
│   │   └── Models/          # Modelos Eloquent
│   ├── database/
│   │   ├── migrations/      # Migraciones de BD
│   │   └── seeders/         # Datos de prueba
│   └── routes/api.php       # Rutas de la API
├── frontend/               # Aplicación React
│   ├── src/
│   │   ├── components/     # Componentes React
│   │   ├── services/       # Servicios API
│   │   └── App.tsx         # Componente principal
│   └── package.json        # Dependencias frontend
├── k8s/                   # Manifiestos Kubernetes
│   ├── mysql-*.yaml       # Configuración MySQL
│   ├── backend-*.yaml     # Configuración Backend
│   ├── frontend-*.yaml    # Configuración Frontend
│   └── ingress.yaml       # Configuración Ingress
├── scripts/               # Scripts de despliegue
│   ├── minikube-deploy.sh # Script de despliegue K8s
│   └── dev-tools.sh       # Herramientas de desarrollo
└── docker-compose.yml     # Configuración Docker
```

## 📸 Capturas de Pantalla

<div align="center">
  <img src="docs/images/screenshot-4.png" alt="Vista principal de la aplicación" width="800"/>
  <p><em>Vista principal del tablero Kanban con tareas organizadas</em></p>
</div>

<div align="center">
  <img src="docs/images/screenshot-1.png" alt="Formulario de creación de tareas" width="800"/>
  <p><em>Vista de la imagen lanzada en Docker</em></p>
</div>


## 🚀 Instalación y Configuración

### Prerrequisitos

#### Para Docker
- **Docker** y **Docker Compose**
- **Node.js 18+** (para desarrollo local)
- **PHP 8.2+** (para desarrollo local)
- **Composer** (para desarrollo local)

#### Para Kubernetes
- **Docker**
- **kubectl**
- **Minikube** (recomendado para desarrollo local)
- **Kind** (alternativa ligera para desarrollo)

### Instalación con Docker (Recomendado)

1. **Clona el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/To-Do-Complete-App.git
   cd To-Do-Complete-App
   ```

2. **Inicia los servicios con Docker Compose**
   ```bash
   docker-compose up -d
   ```

3. **Configura la base de datos**
   ```bash
   # Ejecuta las migraciones
   docker-compose exec backend php artisan migrate
   
   # Opcional: Carga datos de prueba
   docker-compose exec backend php artisan db:seed
   ```

4. **Accede a la aplicación**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - Base de datos: localhost:3307

### Instalación con Kubernetes

#### Opción 1: Minikube (Recomendado)

**Minikube** es ideal para desarrollo local y testing:

1. **Inicia Minikube**
   ```bash
   minikube start
   ```

2. **Despliega la aplicación**
   ```bash
   bash scripts/minikube-deploy.sh
   ```

3. **Configura port-forward para desarrollo**
   ```bash
   bash scripts/dev-tools.sh start-ports
   ```

4. **Accede a la aplicación**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000

#### Opción 2: Kind (Alternativa Ligera)

**Kind** (Kubernetes in Docker) es más ligero y rápido:

1. **Instala Kind**
   ```bash
   # En macOS
   brew install kind
   
   # En Linux
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
   chmod +x ./kind
   sudo mv ./kind /usr/local/bin/kind
   ```

2. **Crea cluster Kind**
   ```bash
   kind create cluster --name todo-app
   ```

3. **Configura kubectl**
   ```bash
   kubectl cluster-info --context kind-todo-app
   ```

4. **Despliega la aplicación**
   ```bash
   bash scripts/minikube-deploy.sh
   ```

#### Comparación: Minikube vs Kind

| Característica | Minikube | Kind |
|---|---|---|
| **Recursos** | Requiere VM | Usa Docker containers |
| **Velocidad de inicio** | Más lento | Más rápido |
| **Compatibilidad** | Muy alta | Alta |
| **Tamaño** | ~2GB | ~500MB |
| **Uso recomendado** | Desarrollo general | CI/CD, testing |

> 📖 **Documentación completa de Kubernetes**: Ver [README-KUBERNETES.md](./README-KUBERNETES.md)

### Instalación para Desarrollo Local

#### Backend (Laravel)
```bash
cd backend

# Instala dependencias PHP
composer install

# Configura el entorno
cp .env.example .env
php artisan key:generate

# Configura la base de datos en .env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=todo_app
DB_USERNAME=tu_usuario
DB_PASSWORD=tu_password

# Ejecuta migraciones
php artisan migrate

# Inicia el servidor de desarrollo
php artisan serve
```

#### Frontend (React)
```bash
cd frontend

# Instala dependencias
npm install

# Inicia el servidor de desarrollo
npm run dev
```

## 📖 Uso de la API

### Endpoints Principales

#### Tareas
```http
GET    /api/tasks              # Obtener todas las tareas
POST   /api/tasks              # Crear nueva tarea
GET    /api/tasks/{id}         # Obtener tarea específica
PUT    /api/tasks/{id}         # Actualizar tarea
DELETE /api/tasks/{id}         # Eliminar tarea
POST   /api/tasks/reorder      # Reordenar tareas
GET    /api/tasks/status/{status} # Filtrar por estado
```

#### Estructura de Tarea
```json
{
  "id": 1,
  "content": "Título de la tarea",
  "description": "Descripción detallada",
  "status": "todo|in-progress|completed|archived",
  "priority": "low|medium|high",
  "assignee": "Nombre del responsable",
  "due_date": "2024-12-31",
  "tags": ["etiqueta1", "etiqueta2"],
  "order": 0,
  "created_at": "2024-01-01T00:00:00.000000Z",
  "updated_at": "2024-01-01T00:00:00.000000Z"
}
```

## 🧪 Testing

### Backend
```bash
cd backend
php artisan test
```

### Frontend
```bash
cd frontend
npm run lint
```

## 🎨 Personalización

### Temas y Estilos
La aplicación utiliza Tailwind CSS para el diseño. Puedes personalizar los colores y estilos modificando:
- `frontend/src/index.css` - Estilos globales
- `frontend/tailwind.config.js` - Configuración de Tailwind

### Estados de Tareas
Los estados disponibles son:
- `todo` - Pendientes (azul)
- `in-progress` - En Progreso (amarillo)
- `completed` - Completadas (verde)
- `archived` - Archivadas (púrpura)

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Estándares de Código
- **PHP**: Sigue PSR-12 y usa Laravel Pint
- **TypeScript**: Usa ESLint y Prettier
- **Commits**: Usa Conventional Commits

## 📝 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👥 Autores

- **Juan Huamani** - *Desarrollo inicial* - [@juanhuamani](https://github.com/juanhuamani)


⭐ **¡Si te gusta este proyecto, no olvides darle una estrella!** ⭐
