# To-Do Complete App - Kubernetes con Kind (Docker Desktop)

Una aplicación completa de gestión de tareas desplegada en Kubernetes usando Kind sobre Docker Desktop.

## 🏗️ Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   MySQL         │
│   (React)       │◄──►│   (Laravel)     │◄──►│   Database      │
│   Port: 3000    │    │   Port: 8000    │    │   Port: 3306    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Ingress       │
                    │   (Nginx)       │
                    │   Port: 80      │
                    └─────────────────┘
```

## 📋 Componentes

### Frontend (React + TypeScript)
- **Puerto**: 3000
- **Tecnología**: React, TypeScript, Vite
- **Funcionalidades**: Interfaz de usuario para gestión de tareas

### Backend (Laravel + PHP)
- **Puerto**: 8000
- **Tecnología**: Laravel, PHP 8.2
- **API**: RESTful API para operaciones CRUD de tareas
- **Base de datos**: MySQL

### Base de Datos (MySQL)
- **Puerto**: 3306
- **Versión**: MySQL 8
- **Almacenamiento**: PersistentVolumeClaim (5Gi)

## 🚀 Despliegue Rápido

### Opción 1: Minikube (Recomendado para desarrollo)

Prerrequisitos: Docker, Minikube, kubectl.

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

### Opción 2: Kind (Alternativa ligera)

Prerrequisitos: Docker, kind, kubectl, y Bash (Git Bash o WSL en Windows).

1. **Crear cluster Kind y desplegar**
   ```bash
   bash scripts/kind-deploy.sh
   ```

El script:
- Construye imágenes locales y las carga en Kind
- Instala `ingress-nginx` para Kind
- Configura almacenamiento dinámico (local-path) y crea `StorageClass` `standard`
- Aplica manifiestos y espera readiness

Acceso:
- Frontend: `http://localhost` (Ingress de nginx en Kind)
- Backend API: `http://localhost/api`
- Alternativa con port-forward:
  - `kubectl port-forward service/frontend 3000:3000`
  - `kubectl port-forward service/backend 8000:8000`

### Comparación: Minikube vs Kind

| Característica | Minikube | Kind |
|---|---|---|
| **Recursos** | Requiere VM | Usa Docker containers |
| **Velocidad de inicio** | Más lento | Más rápido |
| **Compatibilidad** | Muy alta | Alta |
| **Tamaño** | ~2GB | ~500MB |
| **Uso recomendado** | Desarrollo general | CI/CD, testing |
| **Ingress** | Requiere tunnel | Ingress directo |
| **Port-forward** | Necesario para desarrollo | Opcional |
| **Recursos del sistema** | Alto | Bajo |

### Recomendaciones de Uso

- **Minikube**: Para desarrollo local, testing de aplicaciones complejas
- **Kind**: Para CI/CD, testing rápido, desarrollo ligero

## 📁 Estructura de Archivos Kubernetes

```
k8s/
├── mysql-secret.yaml          # Credenciales de MySQL
├── mysql-pvc.yaml             # Volumen persistente para MySQL
├── mysql-service.yaml         # Servicio MySQL
├── mysql-statefulset.yaml     # Deployment MySQL
├── backend-configmap.yaml     # Configuración del backend
├── backend-deployment.yaml    # Deployment del backend
├── backend-service.yaml       # Servicio del backend
├── frontend-deployment.yaml   # Deployment del frontend
├── frontend-service.yaml      # Servicio del frontend
├── ingress.yaml              # Ingress para enrutamiento
└── hpa.yaml                 # Escalamiento automático (HPA)
```

## 🔧 Comandos Útiles

### Escalamiento Horizontal (HPA)

La aplicación incluye **Horizontal Pod Autoscaler (HPA)** para escalamiento automático basado en métricas de CPU y memoria.

#### Configuración del HPA

**Backend:**
- **Min replicas**: 1
- **Max replicas**: 10
- **CPU target**: 70%
- **Memory target**: 80%

**Frontend:**
- **Min replicas**: 1
- **Max replicas**: 5
- **CPU target**: 70%
- **Memory target**: 80%

#### Comportamiento de Escalamiento

**Escalamiento hacia arriba:**
- **Backend**: Máximo 100% o 4 pods por 15 segundos
- **Frontend**: Máximo 50% o 2 pods por 15 segundos

**Escalamiento hacia abajo:**
- **Ambos**: Máximo 10% por 60 segundos
- **Ventana de estabilización**: 300 segundos

#### Comandos HPA

```bash
# Ver estado del HPA
kubectl get hpa

# Ver descripción detallada
kubectl describe hpa backend-hpa
kubectl describe hpa frontend-hpa

# Ver métricas de recursos
kubectl top pods
kubectl top nodes

# Escalar manualmente (desactiva HPA temporalmente)
kubectl scale deployment backend --replicas=3
```

### Gestión de Pods
```bash
# Ver estado de los pods
kubectl get pods

# Ver logs en tiempo real
kubectl logs -f deployment/frontend
kubectl logs -f deployment/backend

# Reiniciar un deployment
kubectl rollout restart deployment/frontend
```

### Gestión de Servicios
```bash
# Ver servicios
kubectl get services

# Ver ingress
kubectl get ingress

# Contextos
kubectl config get-contexts
kubectl config use-context kind-kind-todo
```

### Port-Forward
```bash
# Frontend
kubectl port-forward service/frontend 3000:3000

# Backend
kubectl port-forward service/backend 8000:8000

# MySQL (para debugging)
kubectl port-forward service/mysql 3306:3306
```

### Desarrollo
```bash
# Reconstruir imágenes
docker build -t todo-complete-backend:local ./backend
docker build -t todo-complete-frontend:local ./frontend

# Cargar imágenes en Kind
kind load docker-image todo-complete-backend:local --name kind-todo
kind load docker-image todo-complete-frontend:local --name kind-todo

# Aplicar cambios
kubectl rollout restart deployment/backend
kubectl rollout restart deployment/frontend

# Poblar base de datos con datos de ejemplo
bash scripts/dev-tools.sh seed

# Reiniciar base de datos completamente
bash scripts/dev-tools.sh reset-db
```

### Escalamiento
```bash
# Escalar manualmente
kubectl scale deployment backend --replicas=3
kubectl scale deployment frontend --replicas=2

# Usar herramientas de desarrollo
bash scripts/dev-tools.sh scale-backend
bash scripts/dev-tools.sh scale-frontend

# Ver estado del escalamiento automático
bash scripts/dev-tools.sh hpa-status

# Ver métricas de recursos
kubectl top pods
kubectl top nodes
```

## 🗄️ Base de Datos

### Credenciales
- **Usuario**: user
- **Contraseña**: pass
- **Base de datos**: mydb
- **Usuario root**: rootpass

### Migraciones y Seeding
- **Migraciones**: Se ejecutan automáticamente al iniciar el backend mediante initContainers
- **Seeding**: La base de datos se puebla automáticamente con 8 tareas de ejemplo durante el despliegue

### Conectar a MySQL
```bash
kubectl exec -it mysql-0 -- mysql -uuser -ppass mydb
```

## 🔍 Troubleshooting

### Verificar Estado de la Aplicación
```bash
# Ver todos los recursos
kubectl get all

# Ver logs de errores
kubectl logs deployment/backend --previous
kubectl logs deployment/frontend --previous

# Verificar eventos
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Problemas Comunes

#### 1. Backend Error 500
```bash
# Limpiar cache de Laravel
kubectl exec deployment/backend -- php artisan config:cache
kubectl exec deployment/backend -- php artisan route:cache
kubectl exec deployment/backend -- php artisan view:cache
```

#### 2. Pods no inician
```bash
# Verificar recursos
kubectl describe pod <pod-name>

# Verificar logs de init containers
kubectl logs <pod-name> -c wait-for-mysql
kubectl logs <pod-name> -c run-migrations
```

#### 3. Problemas de conectividad
```bash
# Verificar servicios
kubectl get endpoints

# Probar conectividad interna
kubectl exec deployment/frontend -- curl http://backend:8000
```

## 🧹 Limpieza

### Detener la Aplicación
```bash
kubectl delete all --all
kubectl delete pvc --all
kubectl delete configmap --all
kubectl delete secret --all
kubectl delete ingress --all
```

### Detener Port-Forwards
```bash
pkill -f "kubectl port-forward"
```

### Eliminar cluster Kind
```bash
kind delete cluster --name kind-todo
```

## 📊 Monitoreo

### Dashboard / herramientas
Sugeridas: k9s (`k9s -A --context kind-kind-todo`) o Lens.

### Métricas
```bash
# Habilitar métricas
minikube addons enable metrics-server

# Ver uso de recursos
kubectl top pods
kubectl top nodes
```

## 🔐 Seguridad

### Secrets
Las credenciales de la base de datos se almacenan en Kubernetes Secrets:
```bash
kubectl get secret mysql-secret -o yaml
```

### Network Policies
Para mayor seguridad, se pueden implementar Network Policies para restringir el tráfico entre pods.

## 📝 Notas de Desarrollo

### Variables de Entorno
El backend utiliza las siguientes variables de entorno (inyectadas por ConfigMap/Secret en Kubernetes):
- `APP_ENV`: local
- `APP_DEBUG`: true
- `DB_CONNECTION`: mysql
- `DB_HOST`: mysql (evita tener un `.env` dentro de la imagen con `DB_HOST=db`)
- `DB_PORT`: 3306
- `DB_DATABASE`: mydb
- `DB_USERNAME`: user (desde Secret)
- `DB_PASSWORD`: pass (desde Secret)

### Imágenes Docker
- **Backend**: `todo-complete-backend:local`
- **Frontend**: `todo-complete-frontend:local`

### Puertos Expuestos
- **Frontend**: 3000
- **Backend**: 8000
- **MySQL**: 3306
- **Ingress**: 80

## 🎯 Próximos Pasos

1. **Configurar CI/CD** con GitHub Actions
2. **Implementar Health Checks** más robustos
3. **Agregar Monitoring** con Prometheus/Grafana
4. **Configurar SSL/TLS** para producción
5. **Implementar Auto-scaling** con HPA
6. **Agregar Logging** centralizado con ELK Stack

## 📞 Soporte

Para problemas o preguntas:
1. Revisar los logs: `kubectl logs -f deployment/<service-name>`
2. Verificar el estado: `kubectl get all`
3. Consultar eventos: `kubectl get events`

---

**¡La aplicación está lista para usar!** 🎉

Accede a http://localhost:3000 para comenzar a gestionar tus tareas.
