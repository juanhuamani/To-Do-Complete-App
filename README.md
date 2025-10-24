# 🚀 To-Do App - Autoscaling en Google Cloud Platform

Una aplicación completa de gestión de tareas con **frontend en React**, **backend en Laravel**, y **autoscaling automático** en Google Cloud Platform usando Pulumi y Kubernetes.

## 🎯 Características Principales

✅ **Frontend moderno** - React + TypeScript + Vite  
✅ **Backend robusto** - Laravel + PHP 8.2 + API RESTful  
✅ **Base de datos** - Google Cloud SQL MySQL  
✅ **Containerización** - Docker + Artifact Registry  
✅ **Orquestación** - Google Kubernetes Engine (GKE)  
✅ **Autoscaling** - HPA + Cluster Autoscaler  
✅ **IaC** - Pulumi (open source, no Terraform)  
✅ **GRATIS** - Usando $300 de crédito de Google Cloud  

## 🌐 Acceso a la Aplicación

**URL:** http://34.144.246.195

- **Frontend:** React con Vite
- **Backend:** Laravel con PHP 8.2
- **Base de datos:** Google Cloud SQL MySQL
- **Registro de contenedores:** Google Artifact Registry

## 🏗️ Arquitectura Desplegada

### Infraestructura
- **Cluster GKE:** `todo-cluster-955a689`
- **Región:** `us-central1-a`
- **Máquinas:** `e2-standard-2`
- **Nodos:** 3 (mínimo 1, máximo 3 con autoscaling)

### Servicios Kubernetes
- **Namespace:** `todo`
- **Backend:** 3 réplicas con autoscaling (HPA)
- **Frontend:** 3 réplicas con autoscaling (HPA)
- **Ingress:** Load Balancer con IP estática
- **HPA:** Horizontal Pod Autoscaler configurado

## 🚀 Despliegue Automatizado

### Opción 1: Script Automático (Recomendado)

#### Para Linux/Mac:
```bash
./scripts/deploy-complete.sh
```

#### Para Windows PowerShell:
```powershell
.\scripts\deploy-complete.ps1
```

### Opción 2: Manual

```bash
# 1. Configurar Pulumi
cd pulumi-gcp
npm install
pulumi stack init dev
pulumi config set gcpProject TU_PROJECT_ID
pulumi config set --secret dbPassword "MiPasswordSeguro123!"
pulumi up --yes

# 2. Configurar kubectl
gcloud container clusters get-credentials CLUSTER_NAME --zone us-central1-a

# 3. Desplegar aplicación
kubectl apply -f k8s-gcp/
```

## 🧪 Pruebas de Autoscaling

### Script Automático

#### Para Linux/Mac:
```bash
./scripts/load-test-gcp.sh
```

#### Para Windows PowerShell:
```powershell
.\scripts\load-test-gcp.ps1
```

### Manual

```bash
# Instalar herramienta de carga
go install github.com/rakyll/hey@latest

# Ejecutar prueba de carga
hey -n 1000 -c 15 -t 60 http://34.144.246.195/api/tasks

# Monitorear autoscaling
kubectl get hpa -n todo -w
kubectl get pods -n todo -w
```

## 📋 Prerrequisitos

### Herramientas Necesarias
- **Google Cloud SDK** - [Instalar](https://cloud.google.com/sdk/docs/install)
- **Pulumi** - [Instalar](https://www.pulumi.com/docs/get-started/install/)
- **kubectl** - [Instalar](https://kubernetes.io/docs/tasks/tools/)
- **Docker** - [Instalar](https://docs.docker.com/get-docker/)
- **Node.js** - [Instalar](https://nodejs.org/)

### Cuenta de Google Cloud
- Cuenta de Google Cloud con $300 de crédito gratuito
- Proyecto de GCP creado

## 📁 Estructura del Proyecto

```
To-Do App/
├── frontend/                 # React + TypeScript + Vite
├── backend/                  # Laravel + PHP 8.2
├── k8s-gcp/                  # Manifiestos de Kubernetes para GCP
│   ├── namespace.yaml
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-service.yaml
│   ├── hpa.yaml             # Horizontal Pod Autoscaler
│   ├── ingress.yaml         # Ingress con IP estática
│   ├── backend-configmap.yaml
│   ├── frontend-configmap.yaml
│   ├── mysql-secret.yaml
│   ├── docker-registry-secret.yaml
│   ├── apply-all.sh         # Script de despliegue (Linux/Mac)
│   ├── apply-all.ps1        # Script de despliegue (Windows)
│   └── README.md            # Documentación de Kubernetes
├── pulumi-gcp/              # Infraestructura como Código
│   ├── index.ts             # Configuración de GCP
│   ├── package.json
│   └── Pulumi.dev.yaml
├── scripts/                 # Scripts de automatización
│   ├── deploy-complete.sh   # Despliegue completo (Linux/Mac)
│   ├── deploy-complete.ps1  # Despliegue completo (Windows)
│   ├── load-test-gcp.sh     # Pruebas de carga (Linux/Mac)
│   └── load-test-gcp.ps1    # Pruebas de carga (Windows)
└── README.md               # Este archivo
```

## 🎯 Autoscaling Configurado

### HPA (Horizontal Pod Autoscaler)
- **Backend:** 3-8 pods (CPU 50%, Memoria 60%)
- **Frontend:** 3-5 pods (CPU 50%, Memoria 60%)
- **Escalado suave:** Ventana de estabilización configurada

### GKE Cluster Autoscaler
- **Nodos:** 1-3 nodos automáticamente
- **Máquinas:** e2-small (optimizado para costo)
- **Escalado automático** según demanda

## 💰 Costos y Créditos

### Estimación de Costos
- **Cluster GKE:** ~$0.10/hora (1-3 nodos)
- **Cloud SQL:** ~$0.02/hora
- **Artifact Registry:** ~$0.01/hora
- **Load Balancer:** ~$0.025/hora

**Total estimado:** ~$0.15/hora (~$3.60/día)

### Con $300 de crédito
- **Duración estimada:** ~83 días continuos
- **Para demos:** Semanas de uso intermitente

## 🔧 Comandos Útiles

### Monitoreo
```bash
# Ver estado de la aplicación
kubectl get pods -n todo
kubectl get hpa -n todo
kubectl get ingress -n todo

# Ver logs
kubectl logs -f deployment/backend -n todo
kubectl logs -f deployment/frontend -n todo

# Ver métricas
kubectl top nodes
kubectl top pods -n todo
```

### Troubleshooting
```bash
# Ver detalles de pods
kubectl describe pod POD_NAME -n todo

# Ver eventos
kubectl get events -n todo --sort-by='.lastTimestamp'

# Reiniciar deployments
kubectl rollout restart deployment/backend -n todo
kubectl rollout restart deployment/frontend -n todo
```

## 🧹 Limpieza

### Eliminar Todos los Recursos
```bash
cd pulumi-gcp
pulumi destroy
```

### Eliminar Solo la Aplicación
```bash
kubectl delete namespace todo
```

## 🎉 Demostración de Autoscaling

### Lo que Demuestra
1. **Escalado automático** de pods según la carga
2. **Optimización de recursos** y costos
3. **Alta disponibilidad** y resistencia
4. **Gestión automática** de la carga
5. **Infraestructura como código** con Pulumi

### Beneficios Observados
- ✅ **Escalado automático** según la demanda
- ✅ **Optimización de recursos** y costos
- ✅ **Alta disponibilidad** y resistencia
- ✅ **Gestión automática** de la carga
- ✅ **Infraestructura reproducible** con IaC

## 📊 Métricas de Rendimiento

### Antes del Autoscaling
- **Pods:** 2 backend, 2 frontend
- **Recursos:** Fijos, no escalables

### Durante la Carga
- **Pods:** Escalan automáticamente a 3-8 pods
- **CPU:** Optimización automática
- **Memoria:** Gestión inteligente de recursos

### Después de la Carga
- **Pods:** Reducción automática a niveles óptimos
- **Costos:** Minimización automática
- **Rendimiento:** Mantenimiento de la calidad de servicio

## 🔗 Enlaces Útiles

- **Aplicación:** http://34.144.246.195
- **API:** http://34.144.246.195/api/tasks
- **Health Check:** http://34.144.246.195/api/hello
- **Console GCP:** https://console.cloud.google.com/
- **Billing:** https://console.cloud.google.com/billing

## 🎯 Objetivos Cumplidos

- ✅ **Herramienta IaC:** Pulumi (open source, no Terraform)
- ✅ **Proveedor de nube:** Google Cloud Platform
- ✅ **Autoscaling:** HPA configurado y funcionando
- ✅ **Aplicación completa:** Frontend + Backend + Base de datos
- ✅ **Gratuito:** Usando créditos de $300 de GCP
- ✅ **Demostrable:** Aplicación accesible públicamente
- ✅ **Automatizado:** Scripts de despliegue y pruebas

---

**¡La aplicación está lista para demostrar el autoscaling en GCP! 🎉**

**Tu crédito de $300 es suficiente para correr esto por semanas. ¡Disfruta!**