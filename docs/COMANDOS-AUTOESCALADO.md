# 🚀 Comandos de Autoescalado - EKS Cluster

Guía completa de comandos para gestionar el autoescalado de pods y nodos en el cluster EKS.

---

## 📊 Índice

1. [Escalado de Pods (HPA)](#escalado-de-pods-hpa)
2. [Escalado de Nodos (Cluster Autoscaler)](#escalado-de-nodos-cluster-autoscaler)
3. [Verificación y Monitoreo](#verificación-y-monitoreo)
4. [Pruebas de Autoescalado](#pruebas-de-autoescalado)

---

## 📈 Escalado de Pods (HPA)

### Ver Estado del HPA

```bash
# Ver estado actual del HPA
kubectl get hpa -n todo

# Ver detalles completos del HPA del backend
kubectl describe hpa backend-hpa -n todo

# Ver detalles del HPA del frontend
kubectl describe hpa frontend-hpa -n todo

# Monitorear HPA en tiempo real
kubectl get hpa -n todo -w
```

### Escalar Manualmente los Pods

```bash
# Escalar backend a 5 pods
kubectl scale deployment backend -n todo --replicas=5

# Escalar backend a 8 pods (máximo configurado)
kubectl scale deployment backend -n todo --replicas=8

# Escalar backend a 3 pods (mínimo configurado)
kubectl scale deployment backend -n todo --replicas=3

# Escalar frontend a 5 pods (máximo configurado)
kubectl scale deployment frontend -n todo --replicas=5

# Escalar frontend a 3 pods (mínimo configurado)
kubectl scale deployment frontend -n todo --replicas=3
```

### Configuración del HPA

**Backend HPA:**
- Mínimo: 3 pods
- Máximo: 8 pods
- Target CPU: 50%
- Target Memoria: 60%

**Frontend HPA:**
- Mínimo: 3 pods
- Máximo: 5 pods
- Target CPU: 50%
- Target Memoria: 60%

### Ver Pods Actuales

```bash
# Ver pods del backend
kubectl get pods -n todo -l app=backend

# Ver pods del frontend
kubectl get pods -n todo -l app=frontend

# Ver todos los pods en el namespace todo
kubectl get pods -n todo

# Ver pods con más detalles
kubectl get pods -n todo -o wide
```

### Métricas de Recursos de Pods

```bash
# Ver uso de CPU/Memoria de pods del backend
kubectl top pods -n todo -l app=backend

# Ver uso de CPU/Memoria de pods del frontend
kubectl top pods -n todo -l app=frontend

# Ver uso de CPU/Memoria de todos los pods
kubectl top pods -n todo
```

---

## 🖥️ Escalado de Nodos (Cluster Autoscaler)

### Ver Estado de Nodos

```bash
# Ver nodos actuales
kubectl get nodes

# Ver nodos con más detalles
kubectl get nodes -o wide

# Ver información detallada de un nodo
kubectl describe node <nombre-del-nodo>

# Monitorear nodos en tiempo real
kubectl get nodes -w
```

### Configuración del Cluster Autoscaler

**Configuración Actual:**
- Mínimo: 3 nodos
- Máximo: 3 nodos (puede aumentarse)
- Tipo de instancia: t3.small

### Cambiar Límites de Nodos (Pulumi)

```bash
cd pulumi-aws

# Ver configuración actual
pulumi config get minNodes
pulumi config get maxNodes

# Aumentar máximo de nodos a 5
pulumi config set maxNodes 5

# Aumentar mínimo de nodos a 3
pulumi config set minNodes 3

# Aplicar cambios
pulumi up
```

### Ver Estado del Auto Scaling Group (AWS)

```bash
# Ver estado del Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --region us-east-1 \
  --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'todo-node-group')].[AutoScalingGroupName,MinSize,MaxSize,DesiredCapacity,Instances[*].InstanceId]" \
  --output table
```

### Cluster Autoscaler

```bash
# Ver estado del Cluster Autoscaler
kubectl get deployment cluster-autoscaler -n kube-system

# Ver logs del Cluster Autoscaler
kubectl logs -n kube-system deployment/cluster-autoscaler --tail=50

# Monitorear logs del Cluster Autoscaler en tiempo real
kubectl logs -f -n kube-system deployment/cluster-autoscaler

# Ver eventos del Cluster Autoscaler
kubectl get events -n kube-system | grep cluster-autoscaler
```

---

## ✅ Verificación y Monitoreo

### Verificar Estado General

```bash
# Ver estado completo del cluster
kubectl get all -n todo

# Ver estado del HPA, pods y servicios
kubectl get hpa,pods,svc -n todo

# Ver eventos recientes
kubectl get events -n todo --sort-by='.lastTimestamp' | tail -20
```

### Verificar HPA

```bash
# Ver condiciones del HPA
kubectl describe hpa backend-hpa -n todo | grep -A 10 "Conditions:"

# Ver eventos del HPA
kubectl get events -n todo --field-selector involvedObject.name=backend-hpa --sort-by='.lastTimestamp'

# Ver métricas que usa el HPA
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/namespaces/todo/pods" | jq '.items[] | select(.metadata.labels.app=="backend") | {name: .metadata.name, cpu: .containers[].usage.cpu, memory: .containers[].usage.memory}'
```

### Verificar Métricas Server

```bash
# Verificar que Metrics Server esté instalado
kubectl get deployment metrics-server -n kube-system

# Ver logs del Metrics Server
kubectl logs -n kube-system deployment/metrics-server --tail=20

# Probar que Metrics Server funciona
kubectl top nodes
kubectl top pods -n todo
```

### Verificar Cluster Autoscaler

```bash
# Ver estado del Cluster Autoscaler
kubectl get deployment cluster-autoscaler -n kube-system

# Ver configuración del Cluster Autoscaler
kubectl describe deployment cluster-autoscaler -n kube-system

# Ver logs recientes
kubectl logs -n kube-system deployment/cluster-autoscaler --tail=50

# Buscar mensajes de escalado en los logs
kubectl logs -n kube-system deployment/cluster-autoscaler | grep -i "scale\|node"
```

### Verificar Pods Pendientes

```bash
# Ver pods en estado Pending
kubectl get pods -n todo --field-selector=status.phase=Pending

# Ver detalles de un pod pendiente
kubectl describe pod <nombre-del-pod> -n todo

# Ver eventos de pods pendientes
kubectl get events -n todo --field-selector involvedObject.kind=Pod --sort-by='.lastTimestamp' | grep -i pending
```

### Verificar Capacidad de Nodos

```bash
# Ver recursos disponibles en cada nodo
kubectl describe nodes | grep -A 5 "Allocatable:"

# Ver uso de recursos de nodos
kubectl top nodes

# Ver pods por nodo
kubectl get pods -n todo -o wide --sort-by=.spec.nodeName
```

---

## 🧪 Pruebas de Autoescalado

### Prueba 1: Escalado Manual de Pods

```bash
# 1. Estado inicial
kubectl get hpa -n todo
kubectl get pods -n todo -l app=backend

# 2. Escalar a 8 pods (máximo)
kubectl scale deployment backend -n todo --replicas=8

# 3. Monitorear el escalado
kubectl get pods -n todo -l app=backend -w

# 4. Ver estado del HPA
kubectl get hpa -n todo

# 5. Volver a 3 pods (mínimo)
kubectl scale deployment backend -n todo --replicas=3
```

### Prueba 2: Generar Carga para Activar HPA

```bash
# Obtener URL del backend
BACKEND_URL=$(kubectl get service backend -n todo -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}:8000')

# Generar carga con curl (en bucle)
for i in {1..1000}; do
  curl -s "$BACKEND_URL/api/tasks" > /dev/null &
done

# O usar hey (si está instalado)
hey -n 10000 -c 100 "$BACKEND_URL/api/tasks"

# Monitorear mientras se genera carga
watch -n 2 'kubectl get hpa -n todo && echo "" && kubectl get pods -n todo -l app=backend'
```

### Prueba 3: Forzar Escalado de Nodos

```bash
# 1. Crear deployment temporal con muchos pods que requieren recursos
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stress-high-resources
  namespace: todo
spec:
  replicas: 10
  selector:
    matchLabels:
      app: stress-high-resources
  template:
    metadata:
      labels:
        app: stress-high-resources
    spec:
      containers:
      - name: stress
        image: polinux/stress:latest
        command: ["stress"]
        args: ["--cpu", "1", "--timeout", "300s"]
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
EOF

# 2. Monitorear nodos
kubectl get nodes -w

# 3. Ver pods pendientes
kubectl get pods -n todo -l app=stress-high-resources

# 4. Limpiar después de la prueba
kubectl delete deployment stress-high-resources -n todo
```

### Prueba 4: Monitoreo Completo Durante Prueba

```bash
# Terminal 1: Monitorear HPA
watch -n 2 'kubectl get hpa -n todo && echo "" && kubectl get pods -n todo -l app=backend'

# Terminal 2: Monitorear Nodos
watch -n 5 'kubectl get nodes && echo "" && kubectl get pods -n todo -o wide | grep backend'

# Terminal 3: Monitorear Métricas
watch -n 5 'kubectl top pods -n todo -l app=backend && echo "" && kubectl top nodes'

# Terminal 4: Logs del Cluster Autoscaler
kubectl logs -f -n kube-system deployment/cluster-autoscaler
```

---

## 🎯 Comandos Rápidos de Referencia

### Estado Rápido

```bash
# Ver todo en un comando
kubectl get hpa,pods,svc -n todo && echo "" && kubectl get nodes
```

### Métricas Rápidas

```bash
# Métricas de pods y nodos
kubectl top pods -n todo && echo "" && kubectl top nodes
```

### Escalado Rápido

```bash
# Backend a máximo (8 pods)
kubectl scale deployment backend -n todo --replicas=8

# Backend a mínimo (3 pods)
kubectl scale deployment backend -n todo --replicas=3
```

### Limpieza

```bash
# Limpiar pods terminados
kubectl delete pods -n todo --field-selector=status.phase=Succeeded

# Limpiar pods fallidos
kubectl delete pods -n todo --field-selector=status.phase=Failed
```

---

## 📝 Notas Importantes

### Tiempos de Escalado

- **HPA (Pods):**
  - Escalado hacia arriba: 30-60 segundos
  - Escalado hacia abajo: 5 minutos (stabilization window)

- **Cluster Autoscaler (Nodos):**
  - Escalado hacia arriba: 2-5 minutos
  - Escalado hacia abajo: 10-15 minutos

### Umbrales del HPA

- **CPU:** El HPA escalará cuando el uso promedio de CPU supere el 50%
- **Memoria:** El HPA escalará cuando el uso promedio de memoria supere el 60%
- **Comportamiento:** Usa la métrica más alta (CPU o Memoria) para decidir escalar

### Límites

- **Backend:** Mínimo 3 pods, Máximo 8 pods
- **Frontend:** Mínimo 3 pods, Máximo 5 pods
- **Nodos:** Mínimo 3 nodos, Máximo 3 nodos (configurable en Pulumi)

---

## 🔧 Troubleshooting

### HPA no escala

```bash
# Verificar que Metrics Server esté funcionando
kubectl get deployment metrics-server -n kube-system
kubectl top pods -n todo

# Verificar condiciones del HPA
kubectl describe hpa backend-hpa -n todo

# Ver eventos
kubectl get events -n todo --sort-by='.lastTimestamp'
```

### Nodos no escalan

```bash
# Verificar Cluster Autoscaler
kubectl get deployment cluster-autoscaler -n kube-system

# Ver logs
kubectl logs -n kube-system deployment/cluster-autoscaler --tail=100

# Verificar pods pendientes
kubectl get pods -n todo --field-selector=status.phase=Pending

# Verificar límites del Auto Scaling Group
aws autoscaling describe-auto-scaling-groups --region us-east-1
```

### Métricas no disponibles

```bash
# Verificar Metrics Server
kubectl get deployment metrics-server -n kube-system

# Ver logs del Metrics Server
kubectl logs -n kube-system deployment/metrics-server

# Reiniciar Metrics Server
kubectl rollout restart deployment metrics-server -n kube-system
```

---

## 📚 Referencias

- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Cluster Autoscaler Documentation](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [AWS EKS Autoscaling](https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html)

---

**Última actualización:** Noviembre 2025

