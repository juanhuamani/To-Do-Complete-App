# Configuraciones de Kubernetes para GCP

Este directorio contiene todas las configuraciones de Kubernetes necesarias para desplegar la aplicación To-Do en Google Cloud Platform (GCP).

## Archivos incluidos

### Configuraciones básicas
- `namespace.yaml` - Define el namespace "todo"
- `docker-registry-secret.yaml` - Secret para autenticación con Artifact Registry
- `mysql-secret.yaml` - Secret con credenciales de MySQL
- `backend-configmap.yaml` - Configuración del backend
- `frontend-configmap.yaml` - Configuración del frontend

### Deployments y Services
- `backend-deployment.yaml` - Deployment del backend (Laravel)
- `frontend-deployment.yaml` - Deployment del frontend (React)
- `backend-service.yaml` - Service del backend
- `frontend-service.yaml` - Service del frontend

### Autoscaling y Networking
- `hpa.yaml` - Horizontal Pod Autoscaler
- `ingress.yaml` - Ingress para acceso externo

### Scripts de despliegue
- `apply-all.sh` - Script para Linux/Mac
- `apply-all.ps1` - Script para Windows PowerShell

## Cómo usar

### Opción 1: Script automático (Recomendado)
```bash
# Para Linux/Mac
chmod +x apply-all.sh
./apply-all.sh

# Para Windows PowerShell
.\apply-all.ps1
```

### Opción 2: Manual
```bash
kubectl apply -f namespace.yaml
kubectl apply -f mysql-secret.yaml
kubectl apply -f docker-registry-secret.yaml
kubectl apply -f backend-configmap.yaml
kubectl apply -f frontend-configmap.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f backend-service.yaml
kubectl apply -f frontend-service.yaml
kubectl apply -f hpa.yaml
kubectl apply -f ingress.yaml
```

## Verificación

Después del despliegue, puedes verificar que todo funciona:

```bash
# Verificar pods
kubectl get pods -n todo

# Verificar services
kubectl get services -n todo

# Verificar ingress
kubectl get ingress -n todo

# Verificar HPA
kubectl get hpa -n todo
```

## Acceso a la aplicación

La aplicación estará disponible en: **http://34.144.246.195**

## Notas importantes

- La IP del Ingress es estática y no cambiará
- El backend está configurado para usar Cloud SQL MySQL
- El frontend está configurado para comunicarse con el backend a través del Ingress
- El autoscaling está configurado para escalar automáticamente según la carga
