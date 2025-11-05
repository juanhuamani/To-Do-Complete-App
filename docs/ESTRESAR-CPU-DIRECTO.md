# 🔥 Estresar CPU Directamente con kubectl

## 🎯 Comando Directo (Más Simple)

### Opción 1: Comando Único (Recomendado)

```bash
# Crear un pod temporal que consuma CPU durante 3 minutos
kubectl run stress-cpu \
  -n todo \
  --image=polinux/stress:latest \
  --restart=Never \
  -- stress --cpu 4 --timeout 180s
```

**Explicación:**
- `stress --cpu 4`: Consume 4 cores de CPU
- `--timeout 180s`: Ejecuta por 180 segundos (3 minutos)
- `--restart=Never`: No reinicia el pod cuando termine

### Opción 2: Múltiples Pods (Más Carga)

```bash
# Crear múltiples pods de stress para generar más carga
for i in {1..6}; do
  kubectl run stress-cpu-${i} \
    -n todo \
    --image=polinux/stress:latest \
    --restart=Never \
    -- stress --cpu 2 --timeout 180s &
done
```

### Opción 3: Usar Script Automático

```bash
# Ejecutar script automático
bash scripts/stress-cpu-direct.sh
```

**Configuración por defecto:**
- Duración: 180 segundos (3 minutos)
- CPU Load: 80%
- Crea 2x pods de stress por cada pod del backend

---

## 📊 Monitorear Durante la Prueba

### Terminal 1: Monitorear HPA
```bash
watch -n 2 'kubectl get hpa -n todo && echo "" && kubectl get pods -n todo | grep backend'
```

### Terminal 2: Monitorear CPU
```bash
watch -n 5 'kubectl top pods -n todo && echo "" && kubectl top nodes'
```

### Terminal 3: Monitorear Nodos
```bash
watch -n 5 'kubectl get nodes && echo "" && kubectl get pods -n todo -o wide'
```

---

## 🧹 Limpiar Pods de Stress

### Limpiar todos los pods de stress:
```bash
# Eliminar todos los pods de stress
kubectl delete pod -n todo -l run=stress-cpu

# O eliminar por nombre
kubectl delete pod -n todo stress-cpu-{1..10}

# O eliminar todos los pods temporales
kubectl get pods -n todo | grep stress-cpu | awk '{print $1}' | xargs kubectl delete pod -n todo
```

---

## ⚙️ Personalizar la Carga

### Aumentar CPU por pod:
```bash
kubectl run stress-cpu \
  -n todo \
  --image=polinux/stress:latest \
  --restart=Never \
  -- stress --cpu 8 --timeout 180s  # 8 cores en lugar de 4
```

### Aumentar duración:
```bash
kubectl run stress-cpu \
  -n todo \
  --image=polinux/stress:latest \
  --restart=Never \
  -- stress --cpu 4 --timeout 300s  # 5 minutos en lugar de 3
```

### Crear más pods:
```bash
# Crear 10 pods de stress
for i in {1..10}; do
  kubectl run stress-cpu-${i} \
    -n todo \
    --image=polinux/stress:latest \
    --restart=Never \
    -- stress --cpu 2 --timeout 180s &
done
```

---

## ✅ Verificar que Funciona

### Verificar que los pods de stress están corriendo:
```bash
kubectl get pods -n todo | grep stress-cpu
```

### Verificar que están consumiendo CPU:
```bash
kubectl top pods -n todo | grep stress-cpu
```

### Verificar que el HPA está escalando:
```bash
kubectl get hpa -n todo -w
```

---

## 🎯 Resultado Esperado

1. **HPA escalará pods:**
   - De 3 a 5-8 pods cuando CPU > 50%
   - Tiempo: 30-60 segundos

2. **Cluster Autoscaler escalará nodos:**
   - De 2 a 3 nodos cuando pods no caben
   - Tiempo: 2-5 minutos

---

## 📝 Notas

- Los pods de stress se eliminan automáticamente cuando terminan
- Si usas `--restart=Never`, el pod no se reiniciará
- El comando `stress` consume CPU real, así que el HPA debería detectarlo
- Puedes ajustar `--cpu` según el número de cores disponibles

---

¡Con esto puedes estresar directamente sin modificar el backend! 🔥

