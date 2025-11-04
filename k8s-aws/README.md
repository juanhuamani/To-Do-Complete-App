# Configuraciones de Kubernetes para AWS EKS

Este directorio contiene todas las configuraciones de Kubernetes necesarias para desplegar la aplicación To-Do en AWS EKS.

## Archivos incluidos

### Configuraciones básicas
- `namespace.yaml` - Define el namespace "todo"
- `ecr-registry-secret.yaml` - Secret para autenticación con ECR (será actualizado por el script)
- `mysql-secret.yaml` - Secret con credenciales de MySQL/RDS (el host será actualizado por el script)
- `backend-configmap.yaml` - Configuración del backend
- `frontend-configmap.yaml` - Configuración del frontend

### Deployments y Services
- `backend-deployment.yaml` - Deployment del backend (Laravel)
- `frontend-deployment.yaml` - Deployment del frontend (React)
- `backend-service.yaml` - Service del backend
- `frontend-service.yaml` - Service del frontend (LoadBalancer)

### Autoscaling
- `hpa.yaml` - Horizontal Pod Autoscaler

### Scripts de despliegue
- `apply-all.sh` - Script para aplicar todas las configuraciones

## Cómo usar

### Opción 1: Script automático completo (Recomendado)
```bash
cd ..
bash scripts/deploy-complete-aws.sh
```

Este script hace todo automáticamente:
1. Verifica prerrequisitos
2. Configura autenticación AWS
3. Configura y despliega infraestructura con Pulumi
4. Construye y sube imágenes a ECR
5. Configura kubectl
6. Despliega la aplicación
7. Sembra la base de datos

### Opción 2: Script manual para Kubernetes
Primero asegúrate de que:
1. Tienes kubectl configurado para el cluster EKS
2. Las imágenes ya están en ECR
3. Los secrets están configurados

Entonces ejecuta:
```bash
chmod +x apply-all.sh
./apply-all.sh
```

### Opción 3: Manual
```bash
kubectl apply -f namespace.yaml
kubectl apply -f mysql-secret.yaml
kubectl apply -f ecr-registry-secret.yaml
kubectl apply -f backend-configmap.yaml
kubectl apply -f frontend-configmap.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f backend-service.yaml
kubectl apply -f frontend-service.yaml
kubectl apply -f hpa.yaml
```

## Verificación

Después del despliegue, puedes verificar que todo funciona:

```bash
# Verificar pods
kubectl get pods -n todo

# Verificar services
kubectl get services -n todo

# Verificar HPA
kubectl get hpa -n todo

# Obtener URL del LoadBalancer
kubectl get service frontend -n todo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Acceso a la aplicación

La aplicación estará disponible a través del LoadBalancer de AWS:
```bash
export APP_URL=$(kubectl get service frontend -n todo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Tu aplicación está en: http://$APP_URL"
```

## Notas importantes

1. **Image placeholders**: Los archivos de deployment contienen placeholders que son reemplazados por `deploy-complete-aws.sh`
   - `IMAGE_PLACEHOLDER_BACKEND` - URL de la imagen del backend en ECR
   - `IMAGE_PLACEHOLDER_FRONTEND` - URL de la imagen del frontend en ECR
   - `DB_HOST_PLACEHOLDER` - Host de la base de datos RDS

2. **ECR Secret**: El secret para ECR se configura automáticamente por el script de despliegue

3. **LoadBalancer**: Se crea automáticamente un LoadBalancer de AWS ELB para el frontend

4. **Costos**: El LoadBalancer de AWS tiene un costo (~$0.0225/hora). Considera usar un Ingress con ALB si quieres ahorrar.

## Solución de problemas

### Pods no pueden hacer pull de imágenes
```bash
# Verificar el secret de ECR
kubectl get secret ecr-registry-secret -n todo

# Verificar logs del pod
kubectl logs <pod-name> -n todo
```

### Pods en estado ImagePullBackOff
```bash
# Ver detalles del pod
kubectl describe pod <pod-name> -n todo

# Verificar que el secret existe y es correcto
kubectl get secret ecr-registry-secret -n todo -o yaml
```

### No puedo conectar a la base de datos
```bash
# Verificar el secret de MySQL
kubectl get secret mysql-secret -n todo

# Verificar variables de entorno del pod
kubectl exec <backend-pod-name> -n todo -- env | grep DB_
```

