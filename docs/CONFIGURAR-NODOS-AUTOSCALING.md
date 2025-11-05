# 🔧 Configurar Nodos para Probar Autoscaling

## 🎯 Objetivo

Aumentar el número de nodos para probar el **Cluster Autoscaler** y verificar que escala correctamente cuando hay más carga.

---

## 📋 Configuración Actual

Actualmente tienes:
- **minNodes**: 2 (mínimo)
- **maxNodes**: 3 (máximo)
- **desiredNodes**: 2 (deseado)

---

## 🚀 Aumentar Nodos

### Opción 1: Usar Pulumi Config (Recomendado)

```bash
cd pulumi-aws

# Aumentar a 3 nodos mínimo, 5 máximo
pulumi config set minNodes 3
pulumi config set maxNodes 5
pulumi config set desiredNodes 3

# Verificar configuración
pulumi config

# Aplicar cambios
pulumi up
```

### Opción 2: Editar Pulumi.dev.yaml Directamente

```yaml
config:
  pulumi-aws:minNodes: 3
  pulumi-aws:maxNodes: 5
  pulumi-aws:desiredNodes: 3
```

Luego ejecutar:
```bash
pulumi up
```

---

## 📊 Configuración Recomendada para Prueba

```bash
# Configuración para probar autoscaling de nodos
pulumi config set minNodes 3      # Empezar con 3 nodos
pulumi config set maxNodes 5       # Permitir hasta 5 nodos
pulumi config set desiredNodes 3   # Deseado: 3 nodos
```

**Por qué esta configuración:**
- Con 3 nodos iniciales, es más fácil que el Cluster Autoscaler agregue un 4to o 5to nodo
- Si hay más carga, los pods no cabrán en 3 nodos y se escalará a 4 o 5
- Permite verificar que el autoscaling de nodos funciona correctamente

---

## 🧪 Probar Autoscaling de Nodos

### Paso 1: Aumentar Nodos
```bash
cd pulumi-aws
pulumi config set minNodes 3
pulumi config set maxNodes 5
pulumi config set desiredNodes 3
pulumi up
```

### Paso 2: Esperar a que los nodos estén listos
```bash
# Verificar nodos
kubectl get nodes

# Esperar a que todos estén Ready
watch kubectl get nodes
```

### Paso 3: Aumentar carga para forzar escalamiento
```bash
# Opción 1: Aumentar pods del HPA
# Editar k8s-aws/hpa.yaml y aumentar maxReplicas de backend a 10-15
kubectl apply -f k8s-aws/hpa.yaml

# Opción 2: Estresar los pods del backend
bash scripts/stress-backend-pods.sh

# Opción 3: Crear pods de stress que consuman recursos
for i in {1..10}; do
  kubectl run stress-cpu-${i} \
    -n todo \
    --image=polinux/stress:latest \
    --restart=Never \
    --requests=cpu=1000m,memory=512Mi \
    --limits=cpu=2000m,memory=1Gi \
    -- stress --cpu 2 --timeout 300s &
done
```

### Paso 4: Monitorear escalamiento de nodos
```bash
# Terminal 1: Monitorear nodos
watch -n 5 'kubectl get nodes && echo "" && kubectl get pods -n todo -o wide'

# Terminal 2: Monitorear Cluster Autoscaler
kubectl logs -f -n kube-system -l app=cluster-autoscaler

# Terminal 3: Monitorear pods
kubectl get pods -n todo -w
```

---

## ✅ Verificar que Funciona

### Verificar que hay más nodos:
```bash
kubectl get nodes
```

**Esperado:**
- Inicial: 3 nodos
- Durante carga: 4-5 nodos (si los pods no caben)
- Después: Volver a 3 nodos (después de 10-15 minutos)

### Verificar logs del Cluster Autoscaler:
```bash
kubectl logs -f -n kube-system -l app=cluster-autoscaler | grep -i "scale"
```

**Deberías ver:**
- "Scale up: X nodes -> Y nodes"
- "Node group would scale up"

---

## 📝 Configuración Detallada

### Valores Recomendados:

| Configuración | Valor | Descripción |
|--------------|-------|-------------|
| `minNodes` | 3 | Número mínimo de nodos (empezar con 3) |
| `maxNodes` | 5 | Número máximo de nodos (permitir hasta 5) |
| `desiredNodes` | 3 | Número deseado de nodos (inicial) |
| `instanceType` | t3.small | Tipo de instancia (2 vCPU, 2GB RAM) |

### HPA Configuración (para forzar más carga):

```yaml
# k8s-aws/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: todo
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 3
  maxReplicas: 15  # Aumentar de 8 a 15 para forzar más pods
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

---

## 🎯 Resultado Esperado

1. **Después de `pulumi up`:**
   - 3 nodos corriendo (en lugar de 2)

2. **Durante la prueba de carga:**
   - HPA escala pods: 3 → 10-15 pods
   - Cluster Autoscaler escala nodos: 3 → 4-5 nodos (si los pods no caben)

3. **Después de la carga:**
   - Pods vuelven a 3 (después de 5 minutos)
   - Nodos vuelven a 3 (después de 10-15 minutos)

---

## 💰 Costos

⚠️ **Importante:** Aumentar nodos aumentará los costos:
- **3 nodos t3.small**: ~$0.0208/hora × 3 = ~$0.0624/hora (~$45/mes)
- **5 nodos t3.small**: ~$0.0208/hora × 5 = ~$0.104/hora (~$75/mes)

**Recomendación:**
- Usar solo para pruebas
- Reducir a 2 nodos después de la prueba
- Usar `pulumi config set minNodes 2` y `pulumi up` cuando termines

---

## 🔄 Volver a Configuración Original

```bash
cd pulumi-aws
pulumi config set minNodes 2
pulumi config set maxNodes 3
pulumi config set desiredNodes 2
pulumi up
```

---

¡Con esto puedes probar el autoscaling de nodos correctamente! 🚀

