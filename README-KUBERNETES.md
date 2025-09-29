# To-Do Complete App - Kubernetes con Minikube

Una aplicación completa de gestión de tareas desplegada en Kubernetes usando Minikube.

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

### Prerrequisitos
- Docker
- Minikube
- kubectl

### 1. Iniciar Minikube
```bash
minikube start
```

### 2. Desplegar la Aplicación
```bash
# Ejecutar el script de despliegue
bash scripts/minikube-deploy.sh
```

### 3. Configurar Port-Forward
```bash
# Frontend
kubectl port-forward service/frontend 3000:3000 &

# Backend
kubectl port-forward service/backend 8000:8000 &
```

### 4. Acceder a la Aplicación
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000/api

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
└── ingress.yaml              # Ingress para enrutamiento
```

## 🔧 Comandos Útiles

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

# Obtener IP de Minikube
minikube ip
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
eval "$(minikube docker-env)"
docker build -t todo-complete-backend:local ./backend
docker build -t todo-complete-frontend:local ./frontend

# Aplicar cambios
kubectl rollout restart deployment/backend
kubectl rollout restart deployment/frontend

# Poblar base de datos con datos de ejemplo
bash scripts/dev-tools.sh seed

# Reiniciar base de datos completamente
bash scripts/dev-tools.sh reset-db
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

### Detener Minikube
```bash
minikube stop
# o
minikube delete
```

## 📊 Monitoreo

### Dashboard de Minikube
```bash
minikube dashboard
```

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
El backend utiliza las siguientes variables de entorno:
- `APP_ENV`: local
- `APP_DEBUG`: true
- `DB_CONNECTION`: mysql
- `DB_HOST`: mysql
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
