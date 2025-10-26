# 🚀 Scripts de Gestión del Cluster To-Do App

Este directorio contiene scripts útiles para gestionar y monitorear tu aplicación To-Do desplegada en Google Cloud Kubernetes Engine (GKE).

## 📋 Scripts Disponibles

### 1. `deploy-complete.sh` - Despliegue Completo
Script principal para desplegar toda la aplicación en GCP.

```bash
bash scripts/deploy-complete.sh
```

**Características:**
- ✅ Verificación de prerrequisitos
- 🔐 Configuración de autenticación
- 🏗️ Despliegue de infraestructura con Pulumi
- 🐳 Construcción y subida de imágenes Docker
- 🚀 Despliegue en Kubernetes
- 🌱 Sembrado de base de datos

### 2. `cluster-menu.sh` - Menú Interactivo
Menú completo para gestionar el cluster de forma interactiva.

```bash
bash scripts/cluster-menu.sh
```

**Opciones disponibles:**
- 📊 Información general del cluster
- 🖥️ Información de nodos
- 🐳 Pods del namespace 'todo'
- 🌐 Servicios e Ingress
- 📈 Horizontal Pod Autoscaler (HPA)
- 📝 Logs de pods
- 🔧 Ejecutar comandos en pods
- 📅 Eventos del cluster
- ⚙️ Configuración de recursos
- 🔍 Pruebas de conectividad
- 📊 Métricas de rendimiento
- 🚀 Información de la aplicación

### 3. `cluster-quick.sh` - Comandos Rápidos
Script para comandos rápidos desde la línea de comandos.

```bash
# Ver estado general
bash scripts/cluster-quick.sh status

# Ver pods
bash scripts/cluster-quick.sh pods

# Ver servicios
bash scripts/cluster-quick.sh services

# Ver logs
bash scripts/cluster-quick.sh logs

# Reiniciar pods
bash scripts/cluster-quick.sh restart

# Escalar pods
bash scripts/cluster-quick.sh scale backend 3

# Ver URL de la aplicación
bash scripts/cluster-quick.sh url

# Verificar salud
bash scripts/cluster-quick.sh health

# Ver recursos
bash scripts/cluster-quick.sh resources

# Ver eventos
bash scripts/cluster-quick.sh events

# Abrir menú interactivo
bash scripts/cluster-quick.sh menu

# Mostrar ayuda
bash scripts/cluster-quick.sh help
```

### 4. `cluster-monitor.sh` - Monitoreo en Tiempo Real
Script para monitorear el cluster en tiempo real.

```bash
bash scripts/cluster-monitor.sh
```

**Tipos de monitoreo:**
- 🐳 Monitorear pods
- 📊 Monitorear recursos
- 📝 Monitorear logs en tiempo real
- 📅 Monitorear eventos
- 🔄 Monitoreo completo

## 🛠️ Prerrequisitos

Antes de usar estos scripts, asegúrate de tener instalado:

- **Google Cloud SDK** (`gcloud`)
- **kubectl** (Kubernetes CLI)
- **Docker**
- **Pulumi**

## 🔧 Configuración Inicial

1. **Autenticación en Google Cloud:**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

2. **Configurar proyecto:**
   ```bash
   gcloud config set project TU_PROJECT_ID
   ```

3. **Configurar kubectl:**
   ```bash
   gcloud container clusters get-credentials CLUSTER_NAME --zone ZONE --project PROJECT_ID
   ```

## 📊 Comandos Útiles de kubectl

### Información General
```bash
# Estado del cluster
kubectl cluster-info

# Versión
kubectl version

# Contexto actual
kubectl config current-context
```

### Pods
```bash
# Listar pods
kubectl get pods -n todo

# Describir pod
kubectl describe pod POD_NAME -n todo

# Logs de pod
kubectl logs POD_NAME -n todo

# Ejecutar comando en pod
kubectl exec -it POD_NAME -n todo -- /bin/bash
```

### Servicios
```bash
# Listar servicios
kubectl get services -n todo

# Listar ingress
kubectl get ingress -n todo

# Describir servicio
kubectl describe service SERVICE_NAME -n todo
```

### Escalado
```bash
# Escalar deployment
kubectl scale deployment DEPLOYMENT_NAME -n todo --replicas=3

# Ver estado del escalado
kubectl rollout status deployment/DEPLOYMENT_NAME -n todo
```

### Recursos
```bash
# Uso de recursos de nodos
kubectl top nodes

# Uso de recursos de pods
kubectl top pods -n todo

# Eventos
kubectl get events -n todo --sort-by='.lastTimestamp'
```

## 🚨 Solución de Problemas

### Error de conexión a kubectl
```bash
# Verificar configuración
kubectl config current-context

# Reconfigurar credenciales
gcloud container clusters get-credentials CLUSTER_NAME --zone ZONE --project PROJECT_ID
```

### Pods en estado Pending
```bash
# Verificar eventos
kubectl get events -n todo

# Describir pod
kubectl describe pod POD_NAME -n todo
```

### Problemas de conectividad
```bash
# Verificar servicios
kubectl get services -n todo

# Verificar endpoints
kubectl get endpoints -n todo

# Probar conectividad desde pod
kubectl exec -it POD_NAME -n todo -- curl SERVICE_NAME:PORT
```

## 📈 Monitoreo y Alertas

### Métricas de Rendimiento
- **CPU y Memoria:** `kubectl top nodes` y `kubectl top pods -n todo`
- **Recursos solicitados vs límites:** `kubectl describe nodes`
- **Estado de pods:** `kubectl get pods -n todo -o wide`

### Logs Importantes
- **Backend:** `kubectl logs -l app=backend -n todo`
- **Frontend:** `kubectl logs -l app=frontend -n todo`
- **Eventos del cluster:** `kubectl get events -n todo`

## 🔄 Mantenimiento

### Actualizaciones
```bash
# Actualizar imagen
kubectl set image deployment/DEPLOYMENT_NAME CONTAINER_NAME=NEW_IMAGE -n todo

# Verificar rollout
kubectl rollout status deployment/DEPLOYMENT_NAME -n todo

# Rollback si es necesario
kubectl rollout undo deployment/DEPLOYMENT_NAME -n todo
```

### Limpieza
```bash
# Eliminar recursos específicos
kubectl delete deployment DEPLOYMENT_NAME -n todo

# Eliminar namespace completo
kubectl delete namespace todo
```

## 💡 Consejos

1. **Usa el menú interactivo** (`cluster-menu.sh`) para explorar todas las opciones
2. **Monitorea regularmente** con `cluster-monitor.sh` para detectar problemas
3. **Usa comandos rápidos** (`cluster-quick.sh`) para tareas comunes
4. **Revisa los logs** cuando algo no funcione correctamente
5. **Verifica los eventos** para entender qué está pasando en el cluster

## 🆘 Soporte

Si encuentras problemas:

1. Verifica que kubectl esté configurado correctamente
2. Revisa los logs de los pods
3. Consulta los eventos del cluster
4. Usa el menú interactivo para diagnóstico completo

---

¡Disfruta gestionando tu aplicación To-Do en Google Cloud! 🎉
