# 📊 Guía: Crear Dashboard de CloudWatch para To-Do App

## 🎯 Dashboard Recomendado - Configuración Completa

### Estructura del Dashboard:
1. **EKS Cluster** - Métricas del cluster
2. **EC2 Nodes** - Métricas de los nodos
3. **RDS Database** - Métricas de MySQL
4. **Load Balancers** - Métricas de ELB
5. **Kubernetes Pods** - Métricas de aplicaciones (opcional)

---

## 📐 Paso a Paso: Crear el Dashboard

### Paso 1: Crear el Dashboard

1. Ve a **AWS Console → CloudWatch → Dashboards**
2. Click en **"Create dashboard"**
3. Nombre: `todo-app-dashboard`
4. Click en **"Create dashboard"**

---

## 📊 Widgets Recomendados (Configuración Detallada)

### 1️⃣ **EKS Cluster - CPU Utilization**

**Tipo:** Line chart

**Configuración:**
- **Namespace:** `AWS/EKS`
- **Metric:** `CPUUtilization`
- **Dimension:**
  - Name: `ClusterName`
  - Value: `todo-cluster` (o el nombre de tu cluster)
- **Period:** `1 minute`
- **Statistic:** `Average`
- **Y-axis:** 0-100 (%)

**Título:** "EKS Cluster - CPU Usage (%)"

---

### 2️⃣ **EKS Cluster - Memory Utilization**

**Tipo:** Line chart

**Configuración:**
- **Namespace:** `AWS/EKS`
- **Metric:** `MemoryUtilization`
- **Dimension:**
  - Name: `ClusterName`
  - Value: `todo-cluster`
- **Period:** `1 minute`
- **Statistic:** `Average`
- **Y-axis:** 0-100 (%)

**Título:** "EKS Cluster - Memory Usage (%)"

---

### 3️⃣ **EC2 Nodes - CPU por Nodo**

**Tipo:** Line chart (múltiples líneas)

**Configuración:**
- **Namespace:** `AWS/EC2`
- **Metric:** `CPUUtilization`
- **Dimension:**
  - Name: `AutoScalingGroupName`
  - Value: `todo-node-group` (o el nombre de tu node group)
- **Period:** `1 minute`
- **Statistic:** `Average`
- **Y-axis:** 0-100 (%)

**Título:** "EC2 Nodes - CPU Usage (%)"

**Nota:** Si tienes múltiples nodos, cada uno aparecerá como una línea separada.

---

### 4️⃣ **EC2 Nodes - Network In/Out**

**Tipo:** Stacked area chart

**Configuración:**
- **Métrica 1:**
  - **Namespace:** `AWS/EC2`
  - **Metric:** `NetworkIn`
  - **Dimension:** `AutoScalingGroupName` = `todo-node-group`
  - **Period:** `1 minute`
  - **Statistic:** `Sum`
  
- **Métrica 2:**
  - **Namespace:** `AWS/EC2`
  - **Metric:** `NetworkOut`
  - **Dimension:** `AutoScalingGroupName` = `todo-node-group`
  - **Period:** `1 minute`
  - **Statistic:** `Sum`

**Título:** "EC2 Nodes - Network Traffic (Bytes)"

---

### 5️⃣ **RDS - CPU Utilization**

**Tipo:** Line chart

**Configuración:**
- **Namespace:** `AWS/RDS`
- **Metric:** `CPUUtilization`
- **Dimension:**
  - Name: `DBInstanceIdentifier`
  - Value: `todo-mysql` (o el nombre de tu instancia RDS)
- **Period:** `1 minute`
- **Statistic:** `Average`
- **Y-axis:** 0-100 (%)

**Título:** "RDS MySQL - CPU Usage (%)"

---

### 6️⃣ **RDS - Database Connections**

**Tipo:** Line chart

**Configuración:**
- **Namespace:** `AWS/RDS`
- **Metric:** `DatabaseConnections`
- **Dimension:**
  - Name: `DBInstanceIdentifier`
  - Value: `todo-mysql`
- **Period:** `1 minute`
- **Statistic:** `Average`

**Título:** "RDS MySQL - Active Connections"

---

### 7️⃣ **RDS - Read/Write Latency**

**Tipo:** Line chart (dos líneas)

**Configuración:**
- **Métrica 1:**
  - **Namespace:** `AWS/RDS`
  - **Metric:** `ReadLatency`
  - **Dimension:** `DBInstanceIdentifier` = `todo-mysql`
  - **Period:** `1 minute`
  - **Statistic:** `Average`
  - **Label:** "Read Latency"
  
- **Métrica 2:**
  - **Namespace:** `AWS/RDS`
  - **Metric:** `WriteLatency`
  - **Dimension:** `DBInstanceIdentifier` = `todo-mysql`
  - **Period:** `1 minute`
  - **Statistic:** `Average`
  - **Label:** "Write Latency"

**Título:** "RDS MySQL - Read/Write Latency (ms)"

---

### 8️⃣ **RDS - Freeable Memory**

**Tipo:** Line chart

**Configuración:**
- **Namespace:** `AWS/RDS`
- **Metric:** `FreeableMemory`
- **Dimension:**
  - Name: `DBInstanceIdentifier`
  - Value: `todo-mysql`
- **Period:** `1 minute`
- **Statistic:** `Average`

**Título:** "RDS MySQL - Freeable Memory (Bytes)"

---

### 9️⃣ **Load Balancer - Request Count**

**Tipo:** Line chart

**Configuración:**
- **Namespace:** `AWS/ApplicationELB` (o `AWS/ELB` si es Classic LB)
- **Metric:** `RequestCount`
- **Dimension:**
  - Name: `LoadBalancer`
  - Value: (nombre de tu Load Balancer - lo puedes obtener de la consola)
- **Period:** `1 minute`
- **Statistic:** `Sum`

**Título:** "Load Balancer - Request Count"

---

### 🔟 **Load Balancer - Response Time**

**Tipo:** Line chart

**Configuración:**
- **Namespace:** `AWS/ApplicationELB` (o `AWS/ELB`)
- **Metric:** `TargetResponseTime`
- **Dimension:**
  - Name: `LoadBalancer`
  - Value: (nombre de tu Load Balancer)
- **Period:** `1 minute`
- **Statistic:** `Average`

**Título:** "Load Balancer - Response Time (seconds)"

---

### 1️⃣1️⃣ **Load Balancer - Healthy/Unhealthy Hosts**

**Tipo:** Line chart (dos líneas)

**Configuración:**
- **Métrica 1:**
  - **Namespace:** `AWS/ApplicationELB`
  - **Metric:** `HealthyHostCount`
  - **Dimension:** `LoadBalancer` = (nombre de tu LB)
  - **Period:** `1 minute`
  - **Statistic:** `Average`
  - **Label:** "Healthy Hosts"
  
- **Métrica 2:**
  - **Namespace:** `AWS/ApplicationELB`
  - **Metric:** `UnHealthyHostCount`
  - **Dimension:** `LoadBalancer` = (nombre de tu LB)
  - **Period:** `1 minute`
  - **Statistic:** `Average`
  - **Label:** "Unhealthy Hosts"

**Título:** "Load Balancer - Host Health"

---

### 1️⃣2️⃣ **Load Balancer - HTTP Status Codes**

**Tipo:** Stacked area chart

**Configuración:**
- **Métrica 1:** `HTTPCode_Target_2XX_Count` - Label: "2XX"
- **Métrica 2:** `HTTPCode_Target_4XX_Count` - Label: "4XX"
- **Métrica 3:** `HTTPCode_Target_5XX_Count` - Label: "5XX"

**Namespace:** `AWS/ApplicationELB`
**Dimension:** `LoadBalancer` = (nombre de tu LB)
**Period:** `1 minute`
**Statistic:** `Sum`

**Título:** "Load Balancer - HTTP Status Codes"

---

## 📋 Layout Sugerido del Dashboard

### Fila 1: EKS Cluster
```
[EKS CPU] [EKS Memory] [EC2 Nodes CPU]
```

### Fila 2: Network y Storage
```
[EC2 Network] [RDS CPU] [RDS Connections]
```

### Fila 3: Database Performance
```
[RDS Latency] [RDS Freeable Memory]
```

### Fila 4: Load Balancers
```
[LB Requests] [LB Response Time] [LB Host Health]
```

### Fila 5: HTTP Status
```
[HTTP Status Codes] (ancho completo)
```

---

## 🎨 Widgets Adicionales Útiles

### **Number Widgets (Resumen):**

#### Total Requests (última hora)
- **Tipo:** Number
- **Metric:** `RequestCount`
- **Statistic:** `Sum`
- **Period:** `1 hour`

#### Average Response Time
- **Tipo:** Number
- **Metric:** `TargetResponseTime`
- **Statistic:** `Average`
- **Period:** `1 hour`

#### Active DB Connections
- **Tipo:** Number
- **Metric:** `DatabaseConnections`
- **Statistic:** `Average`
- **Period:** `1 hour`

---

## 🔧 Configuración Avanzada

### Auto-Refresh:
- **Intervalo:** 1-5 minutos
- Activar en la configuración del dashboard

### Time Range:
- **Default:** Last 1 hour
- Opciones: 3 hours, 6 hours, 12 hours, 24 hours

### Period:
- **Recomendado:** 1 minute para métricas en tiempo real
- Alternativa: 5 minutes para reducir carga

---

## 📝 Pasos Detallados para Cada Widget

### Ejemplo: Crear Widget "EKS Cluster - CPU"

1. En el dashboard, click en **"Add widget"**
2. Selecciona **"Line"** (gráfico de líneas)
3. Click en **"Select metric"**
4. En el panel de métricas:
   - **Namespace:** Selecciona `AWS/EKS`
   - **Metric name:** Selecciona `CPUUtilization`
   - **Dimension:** 
     - Name: `ClusterName`
     - Value: `todo-cluster` (o tu nombre de cluster)
5. Click en **"Select metric"**
6. Configura:
   - **Period:** `1 minute`
   - **Statistic:** `Average`
   - **Y-axis label:** `CPU (%)`
   - **Y-axis min:** `0`
   - **Y-axis max:** `100`
7. Click en **"Create widget"**

---

## 🎯 Valores de Dimensiones (Importantes)

### Para encontrar los valores correctos:

#### **Cluster Name:**
```bash
# Desde terminal:
aws eks list-clusters --region us-east-1
# O desde Pulumi:
pulumi stack output clusterName
```

#### **DB Instance Identifier:**
```bash
# Desde terminal:
aws rds describe-db-instances --region us-east-1 --query 'DBInstances[*].DBInstanceIdentifier'
# O desde Pulumi:
pulumi stack output dbHost
```

#### **Load Balancer Name:**
```bash
# Desde terminal:
aws elbv2 describe-load-balancers --region us-east-1 --query 'LoadBalancers[*].LoadBalancerName'
# O desde kubectl:
kubectl get service frontend -n todo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

#### **Auto Scaling Group Name:**
```bash
# Desde terminal:
aws autoscaling describe-auto-scaling-groups --region us-east-1 --query 'AutoScalingGroups[*].AutoScalingGroupName'
# O desde EKS Console: EKS → Clusters → Compute → Node Groups
```

---

## 🚀 Configuración Rápida (Copy-Paste)

### Widget JSON para EKS CPU:
```json
{
  "type": "metric",
  "properties": {
    "metrics": [
      [ "AWS/EKS", "CPUUtilization", { "ClusterName": "todo-cluster" } ]
    ],
    "period": 60,
    "stat": "Average",
    "region": "us-east-1",
    "title": "EKS Cluster - CPU Usage (%)",
    "yAxis": {
      "left": {
        "min": 0,
        "max": 100,
        "label": "CPU (%)"
      }
    }
  }
}
```

### Widget JSON para RDS CPU:
```json
{
  "type": "metric",
  "properties": {
    "metrics": [
      [ "AWS/RDS", "CPUUtilization", { "DBInstanceIdentifier": "todo-mysql" } ]
    ],
    "period": 60,
    "stat": "Average",
    "region": "us-east-1",
    "title": "RDS MySQL - CPU Usage (%)",
    "yAxis": {
      "left": {
        "min": 0,
        "max": 100,
        "label": "CPU (%)"
      }
    }
  }
}
```

---

## ✅ Checklist de Widgets Esenciales

- [ ] EKS Cluster - CPU Utilization
- [ ] EKS Cluster - Memory Utilization
- [ ] EC2 Nodes - CPU (por nodo o agregado)
- [ ] EC2 Nodes - Network In/Out
- [ ] RDS - CPU Utilization
- [ ] RDS - Database Connections
- [ ] RDS - Read/Write Latency
- [ ] RDS - Freeable Memory
- [ ] Load Balancer - Request Count
- [ ] Load Balancer - Response Time
- [ ] Load Balancer - Healthy/Unhealthy Hosts
- [ ] Load Balancer - HTTP Status Codes (2XX, 4XX, 5XX)

---

## 🎨 Mejores Prácticas

1. **Agrupa métricas relacionadas** en la misma fila
2. **Usa colores consistentes** para el mismo tipo de métrica
3. **Configura Y-axis apropiados** para mejor visualización
4. **Habilita auto-refresh** para monitoreo en tiempo real
5. **Guarda diferentes vistas** (1h, 6h, 24h) como dashboards separados

---

## 📱 Acceso Rápido

Una vez creado, tu dashboard estará disponible en:
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=todo-app-dashboard
```

---

¡Con este dashboard tendrás visibilidad completa de tu infraestructura! 🎉

