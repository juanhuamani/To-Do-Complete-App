#!/bin/bash

# Script para verificar la conexión al cluster de Google Cloud
# Te muestra toda la información relevante para confirmar que estás conectado correctamente

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

echo -e "${CYAN}=============================================="
echo -e "🔍 VERIFICACIÓN DE CONEXIÓN A GOOGLE CLOUD"
echo -e "==============================================${NC}"
echo ""

# 1. Verificar autenticación de Google Cloud
print_step "1. Verificando autenticación de Google Cloud"
echo ""

print_info "Cuenta autenticada:"
gcloud auth list --filter=status:ACTIVE --format="value(account)"
echo ""

print_info "Proyecto actual:"
gcloud config get-value project
echo ""

print_info "Región configurada:"
gcloud config get-value compute/region 2>/dev/null || echo "No configurada"
echo ""

print_info "Zona configurada:"
gcloud config get-value compute/zone 2>/dev/null || echo "No configurada"
echo ""

# 2. Verificar contexto de kubectl
print_step "2. Verificando contexto de kubectl"
echo ""

print_info "Contexto actual de kubectl:"
kubectl config current-context
echo ""

print_info "Información del cluster:"
kubectl cluster-info
echo ""

print_info "Versión del servidor Kubernetes:"
kubectl version --output=yaml | grep -E "(serverVersion|clientVersion)" -A 2
echo ""

# 3. Verificar clusters disponibles en GCP
print_step "3. Verificando clusters disponibles en Google Cloud"
echo ""

print_info "Clusters de GKE en tu proyecto:"
gcloud container clusters list
echo ""

# 4. Verificar namespace y recursos
print_step "4. Verificando recursos del cluster"
echo ""

print_info "Namespaces disponibles:"
kubectl get namespaces
echo ""

print_info "Pods en el namespace 'todo':"
kubectl get pods -n todo 2>/dev/null || print_warning "Namespace 'todo' no existe o no tienes acceso"
echo ""

print_info "Nodos del cluster:"
kubectl get nodes
echo ""

# 5. Verificar información específica del cluster
print_step "5. Información detallada del cluster"
echo ""

print_info "Detalles del cluster actual:"
kubectl config view --minify --output jsonpath='{.clusters[0].name}' 2>/dev/null && echo ""
echo ""

print_info "Servidor del cluster:"
kubectl config view --minify --output jsonpath='{.clusters[0].cluster.server}' 2>/dev/null && echo ""
echo ""

# 6. Verificar conectividad con servicios específicos
print_step "6. Verificando conectividad con servicios"
echo ""

print_info "Servicios en el namespace 'todo':"
kubectl get services -n todo 2>/dev/null || print_warning "No hay servicios en el namespace 'todo'"
echo ""

print_info "Ingress en el namespace 'todo':"
kubectl get ingress -n todo 2>/dev/null || print_warning "No hay ingress en el namespace 'todo'"
echo ""

# 7. Verificar información de Pulumi
print_step "7. Verificando información de Pulumi"
echo ""

if [ -d "pulumi-gcp" ]; then
    cd pulumi-gcp
    
    print_info "Stack actual de Pulumi:"
    pulumi stack ls 2>/dev/null || print_warning "No se pudo acceder a Pulumi"
    echo ""
    
    print_info "Configuración del stack:"
    pulumi config 2>/dev/null || print_warning "No se pudo acceder a la configuración"
    echo ""
    
    print_info "Outputs del stack:"
    pulumi stack output 2>/dev/null || print_warning "No se pudieron obtener los outputs"
    echo ""
    
    cd ..
else
    print_warning "Directorio pulumi-gcp no encontrado"
fi

# 8. Resumen final
print_step "8. Resumen de la verificación"
echo ""

print_info "✅ Verificaciones completadas:"
echo "  - Autenticación de Google Cloud: $(gcloud auth list --filter=status:ACTIVE --format="value(account)" | wc -l) cuenta(s) activa(s)"
echo "  - Proyecto configurado: $(gcloud config get-value project)"
echo "  - Contexto de kubectl: $(kubectl config current-context)"
echo "  - Cluster conectado: $(kubectl cluster-info 2>/dev/null | grep 'Kubernetes control plane' | awk '{print $NF}' || echo 'No disponible')"
echo ""

# Verificar si todo está correcto
if kubectl cluster-info >/dev/null 2>&1; then
    print_success "🎉 ¡Estás conectado correctamente al cluster de Google Cloud!"
    echo ""
    print_info "Para gestionar tu cluster, puedes usar:"
    echo "  bash scripts/cluster-menu.sh    # Menú interactivo completo"
    echo "  bash scripts/cluster-quick.sh   # Comandos rápidos"
    echo "  bash scripts/cluster-monitor.sh # Monitoreo en tiempo real"
else
    print_error "❌ No se puede conectar al cluster de Kubernetes"
    echo ""
    print_warning "Para solucionarlo, ejecuta:"
    echo "  gcloud container clusters get-credentials CLUSTER_NAME --zone ZONE --project PROJECT_ID"
fi

echo ""
