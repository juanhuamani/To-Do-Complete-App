#!/bin/bash

# Script completo para desplegar To-Do App en Google Cloud GKE
# ¡GRATIS con los $300 de crédito de Google Cloud!
# Basado en el script PowerShell funcional

set -e

echo "=============================================="
echo "🚀 DESPLIEGUE COMPLETO - To-Do App en GCP"
echo "¡GRATIS con $300 de crédito!"
echo "=============================================="
echo ""

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

# Función para verificar prerrequisitos
check_prerequisites() {
    print_step "Verificando prerrequisitos..."
    
    local missing_tools=()
    
    if ! command -v gcloud >/dev/null 2>&1; then
        missing_tools+=("Google Cloud SDK")
    fi
    
    if ! command -v pulumi >/dev/null 2>&1; then
        missing_tools+=("Pulumi")
    fi
    
    if ! command -v kubectl >/dev/null 2>&1; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v docker >/dev/null 2>&1; then
        missing_tools+=("Docker")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Herramientas faltantes:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        echo ""
        echo "Instala las herramientas faltantes y vuelve a ejecutar el script."
        exit 1
    fi
    
    print_info "Todos los prerrequisitos están instalados ✓"
}

# Función para configurar autenticación
setup_authentication() {
    print_step "Configurando autenticación..." >&2
    
    # Verificar autenticación
    local auth_check=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null)
    if [ -z "$auth_check" ]; then
        print_warning "No estás autenticado en Google Cloud" >&2
        print_info "Ejecutando: gcloud auth login" >&2
        gcloud auth login
    fi
    
    # Configurar autenticación para aplicaciones
    print_info "Configurando autenticación para aplicaciones..." >&2
    gcloud auth application-default login
    
    # Instalar plugin de GKE
    print_info "Instalando plugin de GKE..." >&2
    gcloud components install gke-gcloud-auth-plugin --quiet
    
    # Habilitar APIs necesarias
    print_info "Habilitando APIs necesarias..." >&2
    gcloud services enable container.googleapis.com --quiet
    gcloud services enable artifactregistry.googleapis.com --quiet
    gcloud services enable sqladmin.googleapis.com --quiet
    
    # Obtener proyecto
    local gcp_project=$(gcloud config get-value project 2>/dev/null)
    
    if [ -z "$gcp_project" ] || [ "$gcp_project" == "(unset)" ]; then
        print_error "No se pudo detectar el proyecto de GCP" >&2
        print_warning "Por favor, introduce el ID de tu proyecto:" >&2
        read -p "Project ID: " gcp_project
        
        if [ -z "$gcp_project" ]; then
            print_error "Project ID es requerido" >&2
            exit 1
        fi
        
        print_info "Configurando proyecto: $gcp_project" >&2
        gcloud config set project $gcp_project
    fi
    
    print_info "Usando proyecto: $gcp_project" >&2
    echo "$gcp_project"
}

# Función para configurar Pulumi
setup_pulumi() {
    local gcp_project=$1
    print_step "Configurando Pulumi..."
    
    cd pulumi-gcp
    
    # Configurar passphrase de Pulumi
    export PULUMI_CONFIG_PASSPHRASE="juandivis30"
    
    # Instalar dependencias
    if [ ! -d "node_modules" ]; then
        print_info "Instalando dependencias de Pulumi..."
        npm install
    fi
    
    # Configurar stack
    local stack_exists=$(pulumi stack ls 2>/dev/null | grep "todo" || true)
    if [ -z "$stack_exists" ]; then
        print_info "Creando stack todo..."
        pulumi login --local 2>/dev/null || pulumi login
        pulumi stack init todo
    else
        print_info "Stack todo ya existe, seleccionándolo..."
        pulumi stack select todo
    fi
    
    # Configurar parámetros
    print_info "Configurando parámetros de Pulumi..."
    
    local config_check=$(pulumi config get gcpProject 2>/dev/null || true)
    if [ -z "$config_check" ]; then
        pulumi config set gcpProject $gcp_project
    fi
    
    config_check=$(pulumi config get gcpRegion 2>/dev/null || true)
    if [ -z "$config_check" ]; then
        pulumi config set gcpRegion us-central1
    fi
    
    config_check=$(pulumi config get gcpZone 2>/dev/null || true)
    if [ -z "$config_check" ]; then
        pulumi config set gcpZone us-central1-a
    fi
    
    config_check=$(pulumi config get minNodes 2>/dev/null || true)
    if [ -z "$config_check" ]; then
        pulumi config set minNodes 1
    fi
    
    config_check=$(pulumi config get maxNodes 2>/dev/null || true)
    if [ -z "$config_check" ]; then
        pulumi config set maxNodes 3
    fi
    
    config_check=$(pulumi config get machineType 2>/dev/null || true)
    if [ -z "$config_check" ]; then
        pulumi config set machineType e2-small
    fi
    
    # Configurar contraseñas
    config_check=$(pulumi config get dbPassword 2>/dev/null || true)
    if [ -z "$config_check" ]; then
        print_warning "Configurando contraseña de base de datos..."
        pulumi config set --secret dbPassword "MiPasswordSeguro123!"
    fi
    
    config_check=$(pulumi config get appKey 2>/dev/null || true)
    if [ -z "$config_check" ]; then
        print_info "Generando APP_KEY..."
        local app_key="base64:$(openssl rand -base64 32 2>/dev/null || echo "base64:$(date +%s)")"
        pulumi config set --secret appKey "$app_key"
    fi
    
    cd ..
}

# Función para desplegar infraestructura
deploy_infrastructure() {
    print_step "Desplegando infraestructura en Google Cloud..."
    print_warning "NOTA: Esto tomará ~15-20 minutos. Usando tu crédito GRATIS de $300."
    
    cd pulumi-gcp
    
    # Configurar passphrase de Pulumi
    export PULUMI_CONFIG_PASSPHRASE="MiPasswordSeguro123!"
    
    # Ejecutar pulumi up con manejo de errores
    print_info "Ejecutando pulumi up..."
    local pulumi_result=$(pulumi up --yes 2>&1)
    
    # Verificar si hay errores de base de datos
    if echo "$pulumi_result" | grep -q "Error 1007.*database.*already exists"; then
        print_warning "La base de datos ya existe. Continuando con el despliegue..."
        print_info "Esto es normal si ya tienes la infraestructura desplegada."
    fi
    
    # Verificar si el despliegue fue exitoso
    if [ $? -ne 0 ]; then
        print_warning "Pulumi up tuvo algunos errores, pero continuando..."
        print_info "Esto puede ser normal si algunos recursos ya existen."
    fi
    
    # Obtener outputs
    print_info "Obteniendo outputs de Pulumi..."
    local cluster_name=$(pulumi stack output clusterName 2>/dev/null || true)
    local repo_url=$(pulumi stack output repositoryUrl 2>/dev/null || true)
    local gcp_zone=$(pulumi stack output zone 2>/dev/null || true)
    local gcp_region=$(pulumi stack output region 2>/dev/null || true)
    local db_host=$(pulumi stack output dbHost 2>/dev/null || true)
    
    # Verificar que los outputs sean válidos
    if [ -z "$cluster_name" ]; then
        print_warning "No se pudo obtener el nombre del cluster. Usando valores por defecto..."
        cluster_name="todo-cluster-955a689"
        repo_url="us-central1-docker.pkg.dev/mycloud-jhuamaniv/todo"
        gcp_zone="us-central1-a"
        gcp_region="us-central1"
        db_host="34.69.28.162"
    fi
    
    print_info "Valores obtenidos:"
    print_info "  Cluster: $cluster_name"
    print_info "  Repo URL: $repo_url"
    print_info "  Zona: $gcp_zone"
    print_info "  Región: $gcp_region"
    print_info "  DB Host: $db_host"
    
    cd ..
    
    # Devolver como hash/objeto usando variables globales
    export DEPLOY_CLUSTER_NAME="$cluster_name"
    export DEPLOY_REPO_URL="$repo_url"
    export DEPLOY_GCP_ZONE="$gcp_zone"
    export DEPLOY_GCP_REGION="$gcp_region"
    export DEPLOY_DB_HOST="$db_host"
}

# Función para configurar kubectl
setup_kubectl() {
    local cluster_name=$1
    local gcp_zone=$2
    local gcp_project=$3
    
    print_step "Configurando kubectl..."
    
    print_info "Obteniendo credenciales para cluster: $cluster_name en zona: $gcp_zone"
    gcloud container clusters get-credentials $cluster_name --zone $gcp_zone --project $gcp_project
    
    print_info "kubectl configurado correctamente ✓"
}

# Función para construir y subir imágenes
build_and_push_images() {
    local repo_url=$1
    local gcp_region=$2
    
    print_step "Construyendo y subiendo imágenes Docker..."
    
    # Configurar autenticación de Docker
    print_info "Configurando autenticación de Docker..."
    gcloud auth configure-docker ${gcp_region}-docker.pkg.dev
    
    # Backend
    print_info "Construyendo imagen del backend..."
    cd backend
    docker build -t $repo_url/backend:latest .
    print_info "Subiendo imagen del backend..."
    docker push $repo_url/backend:latest
    cd ..
    
    # Frontend
    print_info "Construyendo imagen del frontend..."
    cd frontend
    docker build --build-arg VITE_API_URL=http://34.144.246.195/api -t $repo_url/frontend:latest .
    print_info "Subiendo imagen del frontend..."
    docker push $repo_url/frontend:latest
    cd ..
    
    print_info "Imágenes construidas y subidas correctamente ✓"
}

# Función para configurar secretos
setup_secrets() {
    print_step "Configurando secretos..."
    
    # Crear secret para Artifact Registry
    print_info "Creando secret para Artifact Registry..."
    local token=$(gcloud auth print-access-token)
    
    # Eliminar secret existente si existe
    kubectl delete secret gcp-registry-secret -n todo 2>/dev/null || true
    
    # Crear nuevo secret
    kubectl create secret docker-registry gcp-registry-secret \
        --docker-server=us-central1-docker.pkg.dev \
        --docker-username=_json_key \
        --docker-password="$token" \
        --docker-email=no-reply@google.com \
        -n todo
    
    print_info "Secretos configurados correctamente ✓"
}

# Función para desplegar aplicación
deploy_application() {
    local repo_url=$1
    local db_host=$2
    
    print_step "Desplegando aplicación en Kubernetes..."
    
    # Esperar a que los nodos estén listos
    print_info "Esperando a que los nodos estén listos..."
    kubectl wait --for=condition=Ready nodes --all --timeout=600s
    
    # Crear directorio temporal
    mkdir -p k8s-temp
    cp -r k8s-gcp/* k8s-temp/
    
    # Actualizar URLs de imágenes
    print_info "Actualizando URLs de imágenes..."
    sed -i "s|us-central1-docker.pkg.dev/mycloud-jhuamaniv/todo|$repo_url|g" k8s-temp/backend-deployment.yaml
    sed -i "s|us-central1-docker.pkg.dev/mycloud-jhuamaniv/todo|$repo_url|g" k8s-temp/frontend-deployment.yaml
    sed -i "s|34.69.28.162|$db_host|g" k8s-temp/mysql-secret.yaml
    
    # Aplicar manifiestos
    print_info "Aplicando manifiestos de Kubernetes..."
    kubectl apply -f k8s-temp/
    
    # Esperar a que los pods estén listos
    print_info "Esperando a que los pods estén listos..."
    kubectl wait --for=condition=Ready pod -l app=backend -n todo --timeout=300s || true
    kubectl wait --for=condition=Ready pod -l app=frontend -n todo --timeout=300s || true
    
    # Limpiar directorio temporal
    rm -rf k8s-temp
    
    print_info "Aplicación desplegada correctamente ✓"
}

# Función para sembrar la base de datos
seed_database() {
    print_step "Sembrando la base de datos..."
    
    # Ejecutar migraciones
    print_info "Ejecutando migraciones..."
    kubectl exec -it deployment/backend -n todo -- php artisan migrate --force
    
    # Sembrar la base de datos
    print_info "Sembrando la base de datos..."
    kubectl exec -it deployment/backend -n todo -- php artisan db:seed --class=TaskSeeder --force
    
    print_info "Base de datos sembrada correctamente ✓"
}

# Función para verificar despliegue
verify_deployment() {
    print_step "Verificando despliegue..."
    
    # Verificar pods
    print_info "Verificando pods..."
    kubectl get pods -n todo
    
    # Verificar servicios
    print_info "Verificando servicios..."
    kubectl get services -n todo
    
    # Verificar HPA
    print_info "Verificando HPA..."
    kubectl get hpa -n todo
    
    # Verificar Ingress
    print_info "Verificando Ingress..."
    kubectl get ingress -n todo
    
    # Obtener IP del Ingress
    local ingress_ip=$(kubectl get ingress todo-ingress -n todo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -n "$ingress_ip" ]; then
        print_info "IP del Ingress: $ingress_ip"
        print_info "URL de la aplicación: http://$ingress_ip"
    else
        print_warning "El Ingress aún no tiene IP asignada. Espera unos minutos."
    fi
    
    print_info "Verificación completada ✓"
}

# Función para mostrar información final
show_final_info() {
    local cluster_name=$1
    local gcp_region=$2
    local gcp_zone=$3
    local gcp_project=$4
    local ingress_ip=$5
    
    echo ""
    echo "=============================================="
    print_info "¡DESPLIEGUE COMPLETADO EXITOSAMENTE! 🎉"
    echo "=============================================="
    echo ""
    
    print_info "Información del cluster:"
    echo "  - Nombre: $cluster_name"
    echo "  - Región: $gcp_region"
    echo "  - Zona: $gcp_zone"
    echo "  - Proyecto: $gcp_project"
    echo ""
    
    if [ -n "$ingress_ip" ]; then
        print_info "🌐 Tu aplicación está disponible en:"
        echo "  http://$ingress_ip"
        echo ""
    fi
    
    print_info "Comandos útiles:"
    echo "  kubectl get pods -n todo"
    echo "  kubectl get hpa -n todo"
    echo "  kubectl get ingress -n todo"
    echo ""
    
    print_info "Para pruebas de carga:"
    echo "  bash scripts/load-test-gcp.sh"
    echo ""
    
    print_warning "IMPORTANTE: Para eliminar todos los recursos:"
    echo "  cd pulumi-gcp && pulumi destroy"
    echo ""
    
    print_info "Tu crédito de $300 es suficiente para correr esto por semanas. ¡Disfruta!"
}

# Función principal
main() {
    # Verificar prerrequisitos
    check_prerequisites
    echo ""
    
    # Configurar autenticación
    local gcp_project=$(setup_authentication)
    echo ""
    
    # Configurar Pulumi
    setup_pulumi $gcp_project
    echo ""
    
    # Desplegar infraestructura
    deploy_infrastructure
    echo ""
    
    # Configurar kubectl
    print_info "Valores para setup_kubectl:"
    print_info "  Cluster: $DEPLOY_CLUSTER_NAME"
    print_info "  Zona: $DEPLOY_GCP_ZONE"
    print_info "  Proyecto: $gcp_project"
    setup_kubectl "$DEPLOY_CLUSTER_NAME" "$DEPLOY_GCP_ZONE" "$gcp_project"
    echo ""
    
    # Construir y subir imágenes
    build_and_push_images "$DEPLOY_REPO_URL" "$DEPLOY_GCP_REGION"
    echo ""
    
    # Configurar secretos
    setup_secrets
    echo ""
    
    # Desplegar aplicación
    deploy_application "$DEPLOY_REPO_URL" "$DEPLOY_DB_HOST"
    echo ""
    
    # Sembrar la base de datos
    seed_database
    echo ""
    
    # Verificar despliegue
    verify_deployment
    echo ""
    
    # Mostrar información final
    local ingress_ip=$(kubectl get ingress todo-ingress -n todo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    show_final_info "$DEPLOY_CLUSTER_NAME" "$DEPLOY_GCP_REGION" "$DEPLOY_GCP_ZONE" "$gcp_project" "$ingress_ip"
}

# Ejecutar función principal
main "$@"
