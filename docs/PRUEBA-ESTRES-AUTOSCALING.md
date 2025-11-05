# 🧪 Guía: Prueba de Estrés para Verificar Autoscaling

## 🎯 Objetivo

Verificar que tanto el **HPA (Horizontal Pod Autoscaler)** como el **Cluster Autoscaler** funcionan correctamente escalando:
1. **Pods** - Cuando hay alta carga de CPU/Memoria
2. **Nodos** - Cuando los pods no caben en los nodos existentes

---

## 📋 Prerrequisitos

1. ✅ Cluster EKS desplegado
2. ✅ Aplicación desplegada (backend y frontend)
3. ✅ HPA configurado (min: 3, max: 8 pods)
4. ✅ Cluster Autoscaler instalado (min: 2, max: 3 nodos)
5. ✅ Metrics Server funcionando
6. ✅ kubectl configurado

---

## 🚀 Ejecutar Prueba de Estrés

### Opción 1: Script Automático (Recomendado)

```bash
# Ejecutar prueba de estrés con configuración por defecto
bash scripts/load-test-aws.sh
```

**Configuración por defecto:**
- Duración: 120 segundos (2 minutos)
- Concurrencia: 50 requests concurrentes
- Rate: 100 requests/segundo

### Opción 2: Personalizar la Prueba

```bash
# Prueba más intensa (5 minutos, 100 concurrentes, 200 req/s)
DURATION=300 CONCURRENCY=100 RATE=200 bash scripts/load-test-aws.sh

# Prueba ligera (1 minuto, 20 concurrentes, 50 req/s)
DURATION=60 CONCURRENCY=20 RATE=50 bash scripts/load-test-aws.sh
```

---

## 📊 Qué Esperar Durante la Prueba

### 1. **Escalamiento de Pods (HPA)**
- **Tiempo:** 30-60 segundos después de iniciar la carga
- **Indicador:** Verás `DESIRED` replicas aumentar en el HPA
- **Comando:** `kubectl get hpa -n todo -w`

### 2. **Escalamiento de Nodos (Cluster Autoscaler)**
- **Tiempo:** 2-5 minutos después de que los pods estén en estado `Pending`
- **Indicador:** Verás nuevos nodos apareciendo
- **Comando:** `kubectl get nodes -w`

### 3. **Secuencia Esperada:**
```
Tiempo 0s:   2 nodos, 3 pods
Tiempo 30s:  2 nodos, 5 pods (HPA escaló)
Tiempo 60s:  2 nodos, 8 pods (HPA máximo)
Tiempo 90s:  Pods en Pending (no caben en 2 nodos)
Tiempo 120s: 3 nodos, 8 pods (Cluster Autoscaler agregó nodo)
```

---

## 🔍 Monitoreo en Tiempo Real

### Terminal 1: Monitorear HPA
```bash
watch -n 2 'kubectl get hpa -n todo && echo "" && kubectl get pods -n todo | grep backend'
```

### Terminal 2: Monitorear Nodos
```bash
watch -n 5 'kubectl get nodes && echo "" && kubectl get pods -n todo -o wide | grep backend'
```

### Terminal 3: Logs del Cluster Autoscaler
```bash
kubectl logs -f -n kube-system -l app=cluster-autoscaler
```

### Terminal 4: Métricas de CPU/Memoria
```bash
watch -n 5 'kubectl top pods -n todo && echo "" && kubectl top nodes'
```

---

## 📈 Métricas a Observar

### HPA (Pod Autoscaling):
```bash
# Ver estado del HPA
kubectl get hpa backend-hpa -n todo

# Ver detalles
kubectl describe hpa backend-hpa -n todo

# Ver eventos
kubectl get events -n todo --sort-by='.lastTimestamp' | grep backend-hpa
```

**Métricas importantes:**
- `CURRENT REPLICAS`: Número actual de pods
- `DESIRED REPLICAS`: Número deseado por el HPA
- `CPU`: % de CPU actual vs target (50%)

### Cluster Autoscaler (Node Autoscaling):
```bash
# Ver estado del Cluster Autoscaler
kubectl get deployment cluster-autoscaler -n kube-system

# Ver logs
kubectl logs -n kube-system -l app=cluster-autoscaler --tail=50

# Ver eventos de escalamiento
kubectl get events -n kube-system | grep cluster-autoscaler
```

**Métricas importantes:**
- Nodos Ready: Debería aumentar de 2 a 3
- Pods Pending: Deberían desaparecer cuando se agrega el nuevo nodo

---

## ✅ Verificación del Escalamiento

### Verificar Escalamiento de Pods:
```bash
# Estado inicial
kubectl get pods -n todo -l app=backend

# Durante la prueba (debería aumentar)
kubectl get pods -n todo -l app=backend | wc -l

# Estado final (después de 2-3 minutos)
kubectl get pods -n todo -l app=backend
```

**Esperado:**
- Inicial: 3 pods
- Durante carga: 5-8 pods
- Final: Volver a 3 pods (después de 5 minutos)

### Verificar Escalamiento de Nodos:
```bash
# Estado inicial
kubectl get nodes

# Durante la prueba (debería aumentar)
kubectl get nodes | wc -l

# Estado final (después de 10-15 minutos)
kubectl get nodes
```

**Esperado:**
- Inicial: 2 nodos
- Durante carga: 3 nodos (si los pods no caben)
- Final: Volver a 2 nodos (después de 10-15 minutos)

---

## 🔧 Troubleshooting

### Los pods no escalan:
```bash
# Verificar HPA
kubectl describe hpa backend-hpa -n todo

# Verificar métricas
kubectl top pods -n todo

# Verificar Metrics Server
kubectl get deployment metrics-server -n kube-system
```

### Los nodos no escalan:
```bash
# Verificar Cluster Autoscaler
kubectl get deployment cluster-autoscaler -n kube-system

# Ver logs
kubectl logs -n kube-system -l app=cluster-autoscaler

# Verificar tags del Node Group
aws autoscaling describe-auto-scaling-groups --region us-east-1 \
  --query 'AutoScalingGroups[*].[AutoScalingGroupName,Tags]'

# Verificar pods en Pending
kubectl get pods -n todo | grep Pending
kubectl describe pod <pod-name> -n todo
```

### Error: "No space left on nodes"
- Esto es **normal** - significa que los pods no caben
- El Cluster Autoscaler debería agregar un nuevo nodo en 2-5 minutos
- Verifica los logs del Cluster Autoscaler

---

## 📊 CloudWatch Dashboard

Durante la prueba, también puedes monitorear en CloudWatch:

1. **EKS Cluster CPU** - Debería aumentar
2. **EC2 Nodes CPU** - Debería aumentar
3. **EC2 Node Count** - Debería aumentar de 2 a 3
4. **RDS CPU** - Puede aumentar si hay muchas queries

---

## 🎯 Resultado Esperado

### ✅ Prueba Exitosa:

1. **HPA escaló pods:**
   - De 3 a 5-8 pods durante la carga
   - CPU/Memoria de pods > 50%

2. **Cluster Autoscaler escaló nodos:**
   - De 2 a 3 nodos cuando pods no cabían
   - Pods en Pending fueron programados

3. **Escalamiento hacia abajo:**
   - Después de 5 minutos: pods vuelven a 3
   - Después de 10-15 minutos: nodos vuelven a 2

---

## 📝 Comandos Útiles

```bash
# Ver todo en un solo comando
kubectl get hpa,pods,nodes -n todo

# Ver métricas de recursos
kubectl top pods -n todo && kubectl top nodes

# Ver eventos recientes
kubectl get events -n todo --sort-by='.lastTimestamp' | tail -20

# Ver estado del Cluster Autoscaler
kubectl describe deployment cluster-autoscaler -n kube-system

# Ver logs del Cluster Autoscaler en tiempo real
kubectl logs -f -n kube-system -l app=cluster-autoscaler
```

---

## 🚨 Notas Importantes

1. **Tiempo de escalamiento:**
   - Pods: 30-60 segundos
   - Nodos: 2-5 minutos

2. **Escalamiento hacia abajo:**
   - Pods: 5 minutos después de que la carga termine
   - Nodos: 10-15 minutos después

3. **Costo:**
   - Durante la prueba habrá 3 nodos (costo adicional)
   - Los nodos se eliminarán automáticamente después

4. **Free Tier:**
   - Si estás en free tier, verifica que no excedas los límites

---

¡Con esto podrás verificar que el autoscaling funciona correctamente en ambos niveles! 🎉

