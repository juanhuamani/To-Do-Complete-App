# 📊 Guía: Cómo Ver tus Recursos en AWS Console

## 🔷 1. EKS Cluster (Kubernetes)

### Ruta:
```
AWS Console → EKS → Clusters → todo-cluster-17d3966
```

### URL directa:
```
https://console.aws.amazon.com/eks/home?region=us-east-1#/clusters/todo-cluster-17d3966
```

### Qué verás:
- ✅ Estado del cluster: **ACTIVE**
- ✅ Versión de Kubernetes
- ✅ Nodos (Node Groups)
- ✅ Configuración de red (VPC, Subnets)
- ✅ Logs del cluster

### Información adicional:
- **Cluster Name**: `todo-cluster-17d3966`
- **Endpoint**: `https://945053C23A2D2DB5D879FA709F655205.gr7.us-east-1.eks.amazonaws.com`
- **Region**: `us-east-1`

---

## 🗄️ 2. RDS Database (MySQL)

### Ruta:
```
AWS Console → RDS → Databases → todo-mysql1356f2a
```

### URL directa:
```
https://console.aws.amazon.com/rds/home?region=us-east-1#database:id=todo-mysql1356f2a
```

### Qué verás:
- ✅ Estado: **available**
- ✅ Tipo de instancia: `db.t3.micro` (Free Tier)
- ✅ Motor: MySQL 8.0.37
- ✅ Endpoint: `todo-mysql1356f2a.c4vky628k3mo.us-east-1.rds.amazonaws.com`
- ✅ Puerto: 3306
- ✅ Base de datos: `mydb`
- ✅ Storage: 20 GB
- ✅ Security Groups asociados

### Información adicional:
- **DB Instance ID**: `todo-mysql1356f2a`
- **Endpoint**: `todo-mysql1356f2a.c4vky628k3mo.us-east-1.rds.amazonaws.com:3306`

---

## 🐳 3. ECR (Container Registry - Imágenes Docker)

### Ruta:
```
AWS Console → ECR → Repositories
```

### URL directa:
```
https://console.aws.amazon.com/ecr/repositories?region=us-east-1
```

### Repositorios:
1. **todo-backend**
   - URI: `895416262297.dkr.ecr.us-east-1.amazonaws.com/todo-backend`
   - Tags: `latest`

2. **todo-frontend**
   - URI: `895416262297.dkr.ecr.us-east-1.amazonaws.com/todo-frontend`
   - Tags: `latest`

### Qué verás:
- ✅ Imágenes subidas
- ✅ Tamaño de las imágenes
- ✅ Última fecha de push
- ✅ Tags de las imágenes
- ✅ Historial de escaneos de seguridad

---

## 🌐 4. Load Balancers (ELB) - Frontend y Backend

### Ruta:
```
AWS Console → EC2 → Load Balancers
```

### URL directa:
```
https://console.aws.amazon.com/ec2/home?region=us-east-1#LoadBalancers:
```

### LoadBalancers activos:

#### Frontend:
- **DNS Name**: `a3bbb1fdd28f74093a87616fa0b22efe-3287916.us-east-1.elb.amazonaws.com`
- **URL**: `http://a3bbb1fdd28f74093a87616fa0b22efe-3287916.us-east-1.elb.amazonaws.com`
- **Tipo**: Application Load Balancer (ALB)
- **Puerto**: 80

#### Backend:
- **DNS Name**: `a6b016b26858e408c882f4fb2815eccb-1251925128.us-east-1.elb.amazonaws.com`
- **URL**: `http://a6b016b26858e408c882f4fb2815eccb-1251925128.us-east-1.elb.amazonaws.com:8000`
- **Tipo**: Application Load Balancer (ALB)
- **Puerto**: 8000

### Qué verás:
- ✅ Estado del Load Balancer (Active/Provisioning)
- ✅ Health checks
- ✅ Target groups (pods de Kubernetes)
- ✅ Reglas de enrutamiento
- ✅ Métricas de tráfico

---

## 💻 5. EC2 Instances (Nodos del Cluster)

### Ruta:
```
AWS Console → EC2 → Instances
```

### URL directa:
```
https://console.aws.amazon.com/ec2/home?region=us-east-1#Instances:
```

### Qué verás:
- ✅ Instancias EC2 que son nodos de EKS
- ✅ Tipo de instancia: `t3.small`
- ✅ Estado: `running`
- ✅ VPC y Subnets donde están
- ✅ Security Groups asociados
- ✅ Tags: `kubernetes.io/cluster/todo: owned`

### Filtrar:
Busca instancias con el tag: `eks:nodegroup-name = todo-node-group`

---

## 🌐 6. VPC (Red Virtual)

### Ruta:
```
AWS Console → VPC → Your VPCs
```

### URL directa:
```
https://console.aws.amazon.com/vpc/home?region=us-east-1#vpcs:
```

### Qué verás:
- ✅ VPC: `todo-vpc-xxxxx`
- ✅ CIDR: `10.0.0.0/16`
- ✅ Subredes públicas y privadas
- ✅ Route tables
- ✅ Internet Gateway
- ✅ NAT Gateway (1 solo para ahorrar costos)

### Recursos relacionados:
- **Subnets**: 4 subredes (2 públicas, 2 privadas)
- **Security Groups**: 
  - `todo-cluster-sg-xx` (para EKS)
  - `todo-db-sg-xx` (para RDS)
  - `eks-cluster-sg-xx` (creado por EKS)

---

## 🔐 7. Security Groups

### Ruta:
```
AWS Console → EC2 → Security Groups
```

### URL directa:
```
https://console.aws.amazon.com/ec2/home?region=us-east-1#SecurityGroups:
```

### Qué verás:
- ✅ Security Groups para EKS
- ✅ Security Groups para RDS (permite MySQL puerto 3306)
- ✅ Reglas de entrada/salida
- ✅ Puertos abiertos

---

## 📊 8. CloudWatch (Métricas y Logs)

### Ruta:
```
AWS Console → CloudWatch
```

### URL directa:
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1
```

### Qué verás:
- ✅ Métricas del cluster EKS
- ✅ Métricas de RDS
- ✅ Métricas de Load Balancers
- ✅ Logs de EKS
- ✅ Alertas configuradas

---

## 💰 9. Billing & Cost Management

### Ruta:
```
AWS Console → Billing & Cost Management → Cost Explorer
```

### URL directa:
```
https://console.aws.amazon.com/cost-management/home?region=us-east-1#/
```

### Qué verás:
- ✅ Costos por servicio:
  - **EKS**: ~$0.10/hora por cluster
  - **EC2**: ~$0.02/hora por instancia t3.small
  - **RDS**: Free Tier elegible (db.t3.micro)
  - **ELB**: ~$0.0225/hora por Load Balancer
  - **ECR**: Storage de imágenes (pocos GB)
  - **Data Transfer**: según uso

### Estimación mensual:
- **Free Tier**: RDS db.t3.micro gratis por 12 meses
- **EKS**: ~$73/mes (solo el cluster, sin nodos)
- **EC2 t3.small**: ~$14.40/mes por instancia
- **Load Balancers**: ~$16/mes cada uno
- **Total aproximado**: ~$120-150/mes (si NO usas Free Tier)

⚠️ **Importante**: t3.small NO está en Free Tier

---

## 🎯 Vista General - Resource Groups

### Ruta:
```
AWS Console → Resource Groups & Tag Editor → Tag Editor
```

### URL directa:
```
https://console.aws.amazon.com/resource-groups/tag-editor?region=us-east-1
```

### Crear un Resource Group:
1. Busca recursos con tag: `Name = todo-*`
2. O busca por tag: `kubernetes.io/cluster/todo = owned`

---

## 📋 Resumen de Recursos Creados

### Resumen:
- ✅ **1 EKS Cluster**: `todo-cluster-17d3966`
- ✅ **1-3 EC2 Instances**: Nodos del cluster (t3.small)
- ✅ **1 RDS Database**: MySQL (db.t3.micro)
- ✅ **2 ECR Repositories**: backend y frontend
- ✅ **2 Load Balancers**: frontend y backend
- ✅ **1 VPC**: Con subredes y NAT Gateway
- ✅ **Multiple Security Groups**: Para EKS y RDS

---

## 🔍 Búsqueda Rápida en Console

### Para encontrar tus recursos:
1. **Busca por nombre**: Todos empiezan con `todo-`
2. **Busca por región**: `us-east-1`
3. **Busca por tags**: `kubernetes.io/cluster/todo`

---

## 🚀 Comandos útiles desde terminal:

```bash
# Ver todos los recursos de EKS
aws eks list-clusters --region us-east-1

# Ver base de datos RDS
aws rds describe-db-instances --region us-east-1

# Ver repositorios ECR
aws ecr describe-repositories --region us-east-1

# Ver Load Balancers
aws elbv2 describe-load-balancers --region us-east-1

# Ver nodos EC2 del cluster
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:kubernetes.io/cluster/todo,Values=owned"
```

---

## 📱 Acceso Rápido - Dashboard Personalizado

1. Ve a **AWS Console → CloudWatch → Dashboards**
2. Crea un dashboard personalizado
3. Agrega widgets para:
   - CPU y memoria de nodos EC2
   - Conexiones de RDS
   - Requests del Load Balancer
   - Pods de Kubernetes

---

¡Ya tienes todo desplegado y funcionando en AWS! 🎉

