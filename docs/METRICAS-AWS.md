# 📊 Guía Completa: Dónde Ver Métricas y Gráficos en AWS

## 🎯 Resumen Rápido

### 1. **CloudWatch** - Métricas y Dashboards Principales
### 2. **EKS Console** - Métricas del Cluster Kubernetes
### 3. **RDS Console** - Métricas de la Base de Datos
### 4. **EC2 Console** - Métricas de los Nodos
### 5. **ELB Console** - Métricas de Load Balancers

---

## 1. 📊 CloudWatch - Dashboard Principal

### Acceso Directo:
```
AWS Console → CloudWatch → Dashboards
URL: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:
```

### Métricas Disponibles:

#### **EKS Cluster Metrics:**
- **CPUUtilization**: Uso de CPU del cluster
- **MemoryUtilization**: Uso de memoria
- **NetworkRxBytes**: Bytes recibidos
- **NetworkTxBytes**: Bytes transmitidos
- **StorageReadBytes**: Lectura de almacenamiento
- **StorageWriteBytes**: Escritura de almacenamiento

**Ruta:** CloudWatch → Metrics → Container Insights → Cluster

#### **EC2 Node Metrics (Nodos del Cluster):**
- **CPUUtilization**: Uso de CPU por nodo
- **NetworkIn**: Tráfico de red entrante
- **NetworkOut**: Tráfico de red saliente
- **DiskReadOps**: Operaciones de lectura de disco
- **DiskWriteOps**: Operaciones de escritura de disco

**Ruta:** CloudWatch → Metrics → EC2 → By Auto Scaling Group

#### **RDS Database Metrics:**
- **CPUUtilization**: Uso de CPU de la base de datos
- **DatabaseConnections**: Conexiones activas
- **FreeableMemory**: Memoria disponible
- **ReadLatency**: Latencia de lectura
- **WriteLatency**: Latencia de escritura
- **ReadThroughput**: Throughput de lectura
- **WriteThroughput**: Throughput de escritura

**Ruta:** CloudWatch → Metrics → RDS → By Database Class

#### **Load Balancer Metrics:**
- **RequestCount**: Número de requests
- **TargetResponseTime**: Tiempo de respuesta
- **HealthyHostCount**: Hosts saludables
- **UnHealthyHostCount**: Hosts no saludables
- **HTTPCode_Target_2XX_Count**: Respuestas 2XX
- **HTTPCode_Target_4XX_Count**: Respuestas 4XX
- **HTTPCode_Target_5XX_Count**: Respuestas 5XX

**Ruta:** CloudWatch → Metrics → ApplicationELB → By LoadBalancer

### Crear Dashboard Personalizado:

1. Ve a **CloudWatch → Dashboards → Create Dashboard**
2. Agrega widgets para:
   - **EKS Cluster**: CPU, Memoria, Red
   - **EC2 Nodes**: CPU por nodo, Network
   - **RDS**: CPU, Conexiones, Latencia
   - **Load Balancers**: Requests, Response Time, HTTP Codes
   - **Kubernetes Pods**: CPU, Memoria (si Container Insights está habilitado)

### Logs de CloudWatch:

**Ruta:** CloudWatch → Logs → Log Groups

Logs disponibles:
- `/aws/eks/todo-cluster/cluster` - Logs del cluster EKS
- `/aws/rds/cluster/todo-mysql` - Logs de RDS (si está habilitado)
- Logs de aplicaciones (si están configurados)

---

## 2. 🎯 EKS Console - Métricas del Cluster

### Acceso Directo:
```
AWS Console → EKS → Clusters → todo-cluster
URL: https://console.aws.amazon.com/eks/home?region=us-east-1#/clusters/todo-cluster
```

### Información Disponible:

#### **Pestaña "Overview":**
- Estado del cluster
- Versión de Kubernetes
- Endpoint del cluster
- Configuración de red (VPC, Subnets)

#### **Pestaña "Compute":**
- Node Groups y sus estados
- Configuración de autoscaling
- Instancias EC2 asociadas

#### **Pestaña "Metrics":**
- CPU Utilization
- Memory Utilization
- Network I/O
- Pod count por namespace

#### **Pestaña "Logs":**
- Logs del cluster (api, audit, authenticator)
- Logs de aplicaciones (si están configurados)

---

## 3. 🗄️ RDS Console - Métricas de Base de Datos

### Acceso Directo:
```
AWS Console → RDS → Databases → todo-mysql
URL: https://console.aws.amazon.com/rds/home?region=us-east-1#database:id=todo-mysql
```

### Métricas Disponibles:

#### **Pestaña "Monitoring":**
- **CPU Utilization**: Gráfico de uso de CPU
- **Database Connections**: Conexiones activas
- **Freeable Memory**: Memoria disponible
- **Read/Write Latency**: Latencia de operaciones
- **Read/Write IOPS**: Operaciones de I/O
- **Network Throughput**: Throughput de red
- **Storage Space**: Espacio de almacenamiento usado

#### **Gráficos Disponibles:**
1. **CPU Utilization** - Uso de CPU en %
2. **Database Connections** - Número de conexiones
3. **Free Storage Space** - Espacio libre
4. **Freeable Memory** - Memoria disponible
5. **Read Latency** - Latencia de lectura (ms)
6. **Write Latency** - Latencia de escritura (ms)
7. **Read Throughput** - Throughput de lectura (bytes/sec)
8. **Write Throughput** - Throughput de escritura (bytes/sec)

### Alertas de RDS:

**Ruta:** RDS → Databases → todo-mysql → Monitoring → Create Alarm

Alertas útiles:
- CPU > 80%
- Freeable Memory < 256MB
- Database Connections > 80% del máximo
- Read Latency > 100ms

---

## 4. 💻 EC2 Console - Métricas de Nodos

### Acceso Directo:
```
AWS Console → EC2 → Instances
URL: https://console.aws.amazon.com/ec2/home?region=us-east-1#Instances:
```

### Métricas Disponibles:

#### **Para cada instancia (nodo del cluster):**
- **CPU Utilization**: Uso de CPU
- **Network In/Out**: Tráfico de red
- **Disk Read/Write Ops**: Operaciones de disco
- **Status Check**: Verificación de estado

#### **Ver todas las métricas:**
1. Selecciona una instancia
2. Ve a la pestaña **"Monitoring"**
3. Verás gráficos de:
   - CPU Utilization
   - Network Utilization
   - Disk I/O
   - Status Checks

#### **CloudWatch Metrics para Nodos:**
- **CPUUtilization**: Por instancia o por Auto Scaling Group
- **NetworkIn/NetworkOut**: Por instancia
- **StatusCheckFailed**: Estado de salud

---

## 5. 🌐 ELB Console - Métricas de Load Balancers

### Acceso Directo:
```
AWS Console → EC2 → Load Balancers
URL: https://console.aws.amazon.com/ec2/home?region=us-east-1#LoadBalancers:
```

### Métricas Disponibles:

#### **Para cada Load Balancer:**
- **Request Count**: Número de requests
- **Target Response Time**: Tiempo de respuesta promedio
- **Healthy/Unhealthy Host Count**: Hosts saludables/no saludables
- **HTTP Codes**: Respuestas 2XX, 4XX, 5XX

#### **Ver métricas detalladas:**
1. Selecciona el Load Balancer
2. Ve a la pestaña **"Monitoring"**
3. Verás gráficos de:
   - Request Count
   - Target Response Time
   - Healthy Host Count
   - HTTP Codes

---

## 6. 📈 Container Insights (Kubernetes)

### Habilitar Container Insights:

```bash
# Instalar Container Insights en el cluster
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/todo-cluster/;s/{{region_name}}/us-east-1/" | kubectl apply -f -
```

### Métricas Disponibles:

**Ruta:** CloudWatch → Container Insights → Performance Monitoring

- **CPU/Memory por Pod**: Métricas detalladas de cada pod
- **Network I/O por Pod**: Tráfico de red por pod
- **Pod Status**: Estado de los pods
- **Node Metrics**: Métricas agregadas de los nodos

---

## 7. 🎨 Crear Dashboard Personalizado

### Pasos para Crear Dashboard:

1. **Ve a CloudWatch → Dashboards → Create Dashboard**

2. **Agrega widgets:**
   - Click en "Add widget"
   - Selecciona tipo: Line, Number, Stacked Area, etc.
   - Selecciona métricas:
     - Namespace: AWS/EKS, AWS/EC2, AWS/RDS, AWS/ApplicationELB
     - Metric: CPUUtilization, NetworkIn, etc.
     - Dimension: Cluster Name, Instance ID, etc.

3. **Configuración recomendada:**
   - **Time Range**: Last 1 hour, Last 3 hours, Last 24 hours
   - **Refresh**: Auto-refresh cada 1-5 minutos
   - **Period**: 1 minute para métricas en tiempo real

### Widgets Recomendados:

1. **EKS Cluster CPU** - Namespace: AWS/EKS, Metric: CPUUtilization
2. **EC2 Node CPU** - Namespace: AWS/EC2, Metric: CPUUtilization
3. **RDS CPU** - Namespace: AWS/RDS, Metric: CPUUtilization
4. **RDS Connections** - Namespace: AWS/RDS, Metric: DatabaseConnections
5. **Load Balancer Requests** - Namespace: AWS/ApplicationELB, Metric: RequestCount
6. **Load Balancer Response Time** - Namespace: AWS/ApplicationELB, Metric: TargetResponseTime

---

## 8. 🔔 Configurar Alarmas

### Alarmas Recomendadas:

#### **EKS Cluster:**
- CPU > 80% durante 5 minutos
- Memory > 80% durante 5 minutos

#### **RDS:**
- CPU > 80% durante 5 minutos
- DatabaseConnections > 80% del máximo
- FreeableMemory < 256MB

#### **EC2 Nodes:**
- CPU > 80% durante 5 minutos
- StatusCheckFailed > 0

#### **Load Balancers:**
- UnhealthyHostCount > 0
- TargetResponseTime > 1000ms
- HTTPCode_Target_5XX_Count > 10

### Crear Alarma:

1. Ve a **CloudWatch → Alarms → Create Alarm**
2. Selecciona métrica
3. Configura condiciones (threshold)
4. Configura SNS topic para notificaciones (opcional)

---

## 9. 📱 Acceso Rápido - URLs Directas

### CloudWatch Dashboard:
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:
```

### EKS Cluster:
```
https://console.aws.amazon.com/eks/home?region=us-east-1#/clusters/todo-cluster
```

### RDS Database:
```
https://console.aws.amazon.com/rds/home?region=us-east-1#database:id=todo-mysql
```

### EC2 Instances:
```
https://console.aws.amazon.com/ec2/home?region=us-east-1#Instances:
```

### Load Balancers:
```
https://console.aws.amazon.com/ec2/home?region=us-east-1#LoadBalancers:
```

---

## 10. 🛠️ Comandos CLI Útiles

### Ver métricas desde terminal:

```bash
# Métricas de EKS Cluster
aws cloudwatch get-metric-statistics \
  --namespace AWS/EKS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=todo-cluster \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average \
  --region us-east-1

# Métricas de RDS
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=todo-mysql \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average \
  --region us-east-1

# Listar todas las métricas disponibles
aws cloudwatch list-metrics --namespace AWS/EKS --region us-east-1
aws cloudwatch list-metrics --namespace AWS/RDS --region us-east-1
aws cloudwatch list-metrics --namespace AWS/EC2 --region us-east-1
```

### Ver métricas de Kubernetes:

```bash
# CPU y memoria de nodos
kubectl top nodes

# CPU y memoria de pods
kubectl top pods -n todo

# Métricas detalladas de un pod
kubectl describe pod POD_NAME -n todo
```

---

## 📝 Resumen

### Dónde Ver Métricas:

1. **CloudWatch** → Dashboard principal con todas las métricas
2. **EKS Console** → Métricas específicas del cluster
3. **RDS Console** → Métricas de la base de datos
4. **EC2 Console** → Métricas de los nodos
5. **ELB Console** → Métricas de Load Balancers

### Próximos Pasos:

1. **Crear un Dashboard personalizado** en CloudWatch
2. **Configurar alarmas** para monitoreo proactivo
3. **Habilitar Container Insights** para métricas detalladas de Kubernetes
4. **Revisar logs** en CloudWatch Logs para debugging

---

¡Con esto tendrás visibilidad completa de tu infraestructura en AWS! 🎉

