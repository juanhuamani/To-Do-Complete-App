#!/bin/bash

# Script completo para desplegar To-Do App en Google Cloud GKE
# ¡GRATIS con los $300 de crédito de Google Cloud!

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

# Función para detectar Windows y configurar PATH
configure_windows_path() {
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]] || [[ -n "$WINDIR" ]]; then
        print_info "Detectado Windows, configurando PATH..."
        
        export PATH="$PATH:/c/Users/$USER/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin"
        export PATH="$PATH:/c/Program Files/Pulumi/bin"
        export PATH="$PATH:/c/Program Files (x86)/Pulumi/bin"
        export PATH="$PATH:$HOME/.pulumi/bin"
        export PATH="$PATH:/c/Program Files/Docker/Docker/resources/bin"
        export PATH="$PATH:/c/Program Files/nodejs"
        export PATH="$PATH:/c/Program Files (x86)/nodejs"
        
        # Crear alias para gcloud si es necesario
        if ! command -v gcloud >/dev/null 2>&1; then
            if [ -f "/c/Users/$USER/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin/gcloud.cmd" ]; then
                gcloud() { "/c/Users/$USER/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin/gcloud.cmd" "$@"; }
                export -f gcloud
            fi
        fi
    fi
}

# Función para verificar prerrequisitos
check_prerequisites() {
    print_step "Verificando prerrequisitos..."
    
    local missing_tools=()
    
    if ! command -v gcloud >/dev/null 2>&1 && ! command -v gcloud.cmd >/dev/null 2>&1; then
        missing_tools+=("Google Cloud SDK")
    fi
    
    if ! command -v pulumi >/dev/null 2>&1 && ! command -v pulumi.exe >/dev/null 2>&1; then
        missing_tools+=("Pulumi")
    fi
    
    if ! command -v kubectl >/dev/null 2>&1 && ! command -v kubectl.exe >/dev/null 2>&1; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v docker >/dev/null 2>&1 && ! command -v docker.exe >/dev/null 2>&1; then
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
    print_step "Configurando autenticación..."
    
    local gcloud_cmd="gcloud"
    if [[ -n "$WINDIR" ]] && command -v gcloud.cmd >/dev/null 2>&1; then
        gcloud_cmd="gcloud.cmd"
    fi
    
    # Verificar autenticación
    if ! $gcloud_cmd auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "."; then
        print_warning "No estás autenticado en Google Cloud"
        print_info "Ejecutando: $gcloud_cmd auth login"
        $gcloud_cmd auth login
    fi
    
    # Configurar autenticación para aplicaciones
    print_info "Configurando autenticación para aplicaciones..."
    $gcloud_cmd auth application-default login
    
    # Instalar plugin de GKE
    print_info "Instalando plugin de GKE..."
    $gcloud_cmd components install gke-gcloud-auth-plugin --quiet
    
    # Habilitar APIs necesarias
    print_info "Habilitando APIs necesarias..."
    $gcloud_cmd services enable container.googleapis.com --quiet
    $gcloud_cmd services enable artifactregistry.googleapis.com --quiet
    $gcloud_cmd services enable sqladmin.googleapis.com --quiet
    
    # Obtener proyecto
    local gcp_project=$($gcloud_cmd config get-value project 2>/dev/null)
    
    if [ -z "$gcp_project" ] || [ "$gcp_project" == "(unset)" ]; then
        print_error "No se pudo detectar el proyecto de GCP"
        print_warning "Por favor, introduce el ID de tu proyecto:"
        read -p "Project ID: " gcp_project
        
        if [ -z "$gcp_project" ]; then
            print_error "Project ID es requerido"
            exit 1
        fi
        
        print_info "Configurando proyecto: $gcp_project"
        $gcloud_cmd config set project $gcp_project
    fi
    
    print_info "Usando proyecto: $gcp_project"
    echo "$gcp_project"
}

# Función para configurar Pulumi
setup_pulumi() {
    print_step "Configurando Pulumi..."
    
    local gcp_project=$1
    cd pulumi-gcp
    
    # Instalar dependencias
    if [ ! -d "node_modules" ]; then
        print_info "Instalando dependencias de Pulumi..."
        npm install
    fi
    
    # Configurar stack
    if ! pulumi stack ls 2>/dev/null | grep -q "dev"; then
        print_info "Creando stack dev..."
        pulumi login --local 2>/dev/null || pulumi login
        pulumi stack init dev
    else
        print_info "Stack dev ya existe, seleccionándolo..."
        pulumi stack select dev
    fi
    
    # Configurar parámetros
    print_info "Configurando parámetros de Pulumi..."
    
    if ! pulumi config get gcpProject >/dev/null 2>&1; then
        pulumi config set gcpProject $gcp_project
    fi
    
    if ! pulumi config get gcpRegion >/dev/null 2>&1; then
        pulumi config set gcpRegion us-central1
    fi
    
    if ! pulumi config get gcpZone >/dev/null 2>&1; then
        pulumi config set gcpZone us-central1-a
    fi
    
    if ! pulumi config get minNodes >/dev/null 2>&1; then
        pulumi config set minNodes 1
    fi
    
    if ! pulumi config get maxNodes >/dev/null 2>&1; then
        pulumi config set maxNodes 3
    fi
    
    if ! pulumi config get machineType >/dev/null 2>&1; then
        pulumi config set machineType e2-small
    fi
    
    # Configurar contraseñas
    if ! pulumi config get dbPassword >/dev/null 2>&1; then
        print_warning "Configurando contraseña de base de datos..."
        pulumi config set --secret dbPassword "MiPasswordSeguro123!"
    fi
    
    if ! pulumi config get appKey >/dev/null 2>&1; then
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
    pulumi up --yes
    
    # Obtener outputs
    local cluster_name=$(pulumi stack output clusterName)
    local repo_url=$(pulumi stack output repositoryUrl)
    local gcp_zone=$(pulumi stack output zone)
    local gcp_region=$(pulumi stack output region)
    local db_host=$(pulumi stack output databaseHost)
    
    cd ..
    
    echo "$cluster_name|$repo_url|$gcp_zone|$gcp_region|$db_host"
}

# Función para configurar kubectl
setup_kubectl() {
    print_step "Configurando kubectl..."
    
    local cluster_name=$1
    local gcp_zone=$2
    local gcp_project=$3
    
    gcloud container clusters get-credentials $cluster_name --zone $gcp_zone --project $gcp_project
    
    print_info "kubectl configurado correctamente ✓"
}

# Función para construir y subir imágenes
build_and_push_images() {
    print_step "Construyendo y subiendo imágenes Docker..."
    
    local repo_url=$1
    local gcp_region=$2
    
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
    docker build -t $repo_url/frontend:latest .
    print_info "Subiendo imagen del frontend..."
    docker push $repo_url/frontend:latest
    cd ..
    
    print_info "Imágenes construidas y subidas correctamente ✓"
}

# Función para desplegar aplicación
deploy_application() {
    print_step "Desplegando aplicación en Kubernetes..."
    
    local repo_url=$1
    local db_host=$2
    
    # Esperar a que los nodos estén listos
    print_info "Esperando a que los nodos estén listos..."
    kubectl wait --for=condition=Ready nodes --all --timeout=600s
    
    # Crear directorio temporal
    mkdir -p k8s-temp
    cp -r k8s-gcp/* k8s-temp/
    
    # Actualizar URLs de imágenes
    print_info "Actualizando URLs de imágenes..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|us-central1-docker.pkg.dev/mycloud-jhuamaniv/todo|$repo_url|g" k8s-temp/backend-deployment.yaml
        sed -i '' "s|us-central1-docker.pkg.dev/mycloud-jhuamaniv/todo|$repo_url|g" k8s-temp/frontend-deployment.yaml
        sed -i '' "s|34.69.28.162|$db_host|g" k8s-temp/mysql-secret.yaml
    else
        # Linux/Windows
        sed -i "s|us-central1-docker.pkg.dev/mycloud-jhuamaniv/todo|$repo_url|g" k8s-temp/backend-deployment.yaml
        sed -i "s|us-central1-docker.pkg.dev/mycloud-jhuamaniv/todo|$repo_url|g" k8s-temp/frontend-deployment.yaml
        sed -i "s|34.69.28.162|$db_host|g" k8s-temp/mysql-secret.yaml
    fi
    
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

# Función para configurar secretos
setup_secrets() {
    print_step "Configurando secretos..."
    
    # Crear secret para Artifact Registry
    print_info "Creando secret para Artifact Registry..."
    kubectl create secret docker-registry gcp-registry-secret \
        --docker-server=us-central1-docker.pkg.dev \
        --docker-username=_json_key \
        --docker-password="$(gcloud auth print-access-token)" \
        --docker-email=no-reply@google.com \
        -n todo \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_info "Secretos configurados correctamente ✓"
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
    # Configurar Windows si es necesario
    configure_windows_path
    
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
    local infra_output=$(deploy_infrastructure)
    local cluster_name=$(echo $infra_output | cut -d'|' -f1)
    local repo_url=$(echo $infra_output | cut -d'|' -f2)
    local gcp_zone=$(echo $infra_output | cut -d'|' -f3)
    local gcp_region=$(echo $infra_output | cut -d'|' -f4)
    local db_host=$(echo $infra_output | cut -d'|' -f5)
    echo ""
    
    # Configurar kubectl
    setup_kubectl $cluster_name $gcp_zone $gcp_project
    echo ""
    
    # Construir y subir imágenes
    build_and_push_images $repo_url $gcp_region
    echo ""
    
    # Configurar secretos
    setup_secrets
    echo ""
    
    # Desplegar aplicación
    deploy_application $repo_url $db_host
    echo ""
    
    # Verificar despliegue
    verify_deployment
    echo ""
    
    # Mostrar información final
    local ingress_ip=$(kubectl get ingress todo-ingress -n todo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    show_final_info $cluster_name $gcp_region $gcp_zone $gcp_project $ingress_ip
}

# Ejecutar función principal
main "$@"
