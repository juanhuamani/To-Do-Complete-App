# 🚀 To-Do App - Infraestructura en AWS con Pulumi

Este directorio contiene la configuración de Pulumi para desplegar la aplicación To-Do en AWS usando EKS (Elastic Kubernetes Service).

## 🎯 Características

- ✅ **EKS Cluster** - Kubernetes administrado por AWS
- ✅ **RDS MySQL** - Base de datos administrada (db.t3.micro - Free Tier)
- ✅ **ECR** - Container Registry para las imágenes
- ✅ **VPC** - Red privada con subredes públicas y privadas
- ✅ **AutoScaling** - Node Group con escalado automático
- ✅ **GRATIS** - Usando AWS Free Tier

## 📋 Prerrequisitos

1. **AWS CLI** - [Instalar](https://aws.amazon.com/cli/)
2. **Pulumi** - [Instalar](https://www.pulumi.com/docs/get-started/install/)
3. **kubectl** - [Instalar](https://kubernetes.io/docs/tasks/tools/)
4. **Docker** - [Instalar](https://docs.docker.com/get-docker/)

## 🔧 Configuración Inicial

### 1. Autenticar AWS

```bash
aws configure
```

### 2. Inicializar Pulumi

```bash
cd pulumi-aws
npm install
pulumi stack init dev
```

### 3. Configurar Secrets

```bash
# Configurar contraseña de DB
pulumi config set --secret dbPassword "MiPasswordSeguro123!"

# Configurar APP_KEY de Laravel
pulumi config set --secret appKey "base64:TuClaveBase64Aqui"
```

### 4. Opciones de Configuración (opcional)

```bash
# Región (default: us-east-1)
pulumi config set awsRegion us-east-1

# Número de nodos mínimo (default: 1)
pulumi config set minNodes 1

# Número de nodos máximo (default: 3)
pulumi config set maxNodes 3

# Tipo de instancia (default: t3.small)
pulumi config set instanceType t3.small
```

## 🚀 Desplegar

```bash
pulumi up
```

## 📊 Verificar

```bash
# Ver el estado de la infraestructura
pulumi stack

# Ver outputs
pulumi stack output

# Configurar kubectl
aws eks update-kubeconfig --name CLUSTER_NAME --region us-east-1

# Verificar cluster
kubectl get nodes
```

## 💰 Costos

### AWS Free Tier Incluye:
- **EC2**: 750 horas/mes de t2.micro (12 meses)
- **RDS**: db.t2.micro (20GB storage) por 12 meses
- **S3**: 5GB almacenamiento
- **VPC**: Gratis
- **EKS**: Cluster gratuito, pagas por los nodos

### Costos Estimados:
- **EKS Cluster**: $0/mes (gratis)
- **EC2 t3.small (3 nodos)**: ~$30/mes (no free tier)
- **RDS db.t3.micro**: $0/mes (Free Tier)
- **ECR**: ~$0.10/mes (primeros 500MB)

**Total estimado:** ~$30-50/mes (puedes reducir a 1 nodo para ~$15/mes)

## 🧹 Limpieza

```bash
# Destruir toda la infraestructura
pulumi destroy
```

## 📝 Notas Importantes

1. **t3.small no es free tier**: Cambia a `t2.micro` si quieres usar free tier (pero es más lento)
2. **MinNodes=1**: Para minimizar costos, usa 1 nodo mínimo
3. **1 NAT Gateway**: Configurado para ahorrar costos (solo 1 en vez de 2)
4. **Region us-east-1**: Usa esta región para mejor compatibilidad con free tier

## 🔗 Enlaces Útiles

- [AWS Free Tier](https://aws.amazon.com/free/)
- [EKS Pricing](https://aws.amazon.com/eks/pricing/)
- [EC2 Free Tier](https://aws.amazon.com/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc)

