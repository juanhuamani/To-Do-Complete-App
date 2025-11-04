#!/bin/bash

# Script completo para desplegar To-Do App en AWS EKS
# ¡Con AWS Free Tier puedes correr esto GRATIS!

set -e

echo "=============================================="
echo "🚀 DESPLIEGUE COMPLETO - To-Do App en AWS"
echo "✨ Usando AWS Free Tier"
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
    
    if ! command -v aws >/dev/null 2>&1; then
        missing_tools+=("AWS CLI")
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
    
    if ! command -v node >/dev/null 2>&1; then
        missing_tools+=("Node.js")
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

# Función para verificar autenticación AWS
check_aws_auth() {
    print_step "Verificando autenticación AWS..."
    
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "No estás autenticado en AWS"
        print_info "Ejecuta: aws configure"
        print_info "O configura las variables de entorno AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY"
        exit 1
    fi
    
    local aws_account=$(aws sts get-caller-identity --query Account --output text)
    local aws_region=$(aws configure get region || echo "us-east-1")
    
    print_info "Autenticado en AWS"
    print_info "  Account: $aws_account"
    print_info "  Región: $aws_region"
    
    export AWS_REGION="$aws_region"
}

# Función para configurar Pulumi
setup_pulumi() {
    print_step "Configurando Pulumi..."
    
    cd pulumi-aws
    
    # Configurar passphrase de Pulumi
    export PULUMI_CONFIG_PASSPHRASE="MiPasswordSeguro123!"
    
    # Instalar dependencias
    if [ ! -d "node_modules" ]; then
        print_info "Instalando dependencias de Pulumi..."
        npm install
    fi
    
    # Configurar stack
    local organization=$(pulumi org get-current 2>/dev/null || echo "organization")
    local project="todo-aws"
    local stack_name="dev"
    local full_stack_name="$organization/$project/$stack_name"
    
    local stack_exists=$(pulumi stack ls 2>/dev/null | grep "$stack_name" || true)
    if [ -z "$stack_exists" ]; then
        print_info "Creando stack $full_stack_name..."
        pulumi stack init "$full_stack_name" 2>/dev/null || pulumi stack init "$stack_name"
        pulumi stack select "$full_stack_name" 2>/dev/null || pulumi stack select "$stack_name"
    else
        print_info "Stack $stack_name ya existe, seleccionándolo..."
        pulumi stack select "$full_stack_name" 2>/dev/null || pulumi stack select "$stack_name"
    fi
    
    # Configurar parámetros
    print_info "Configurando parámetros de Pulumi..."
    
    local config_check=$(pulumi config get awsRegion 2>/dev/null || true)
    if [ -z "$config_check" ]; then
        pulumi config set awsRegion us-east-1
    fi
    
    config_check=$(pulumi config get minNodes 2>/dev/null || true)
    if [ -z "$config_check" ]; then
        pulumi config set minNodes 2
    fi
    
    config_check=$(pulumi config get maxNodes 2>/dev/null || true)
    if [ -z "$config_check" ]; then
        pulumi config set maxNodes 3
    fi
    
    config_check=$(pulumi config get instanceType 2>/dev/null || true)
    if [ -z "$config_check" ]; then
        pulumi config set instanceType t3.small
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
    print_step "Desplegando infraestructura en AWS..."
    print_warning "NOTA: Esto tomará ~20-30 minutos. Creando EKS cluster, RDS y ECR."
    
    cd pulumi-aws
    
    # Configurar passphrase de Pulumi
    export PULUMI_CONFIG_PASSPHRASE="MiPasswordSeguro123!"
    
    # Ejecutar pulumi up
    print_info "Ejecutando pulumi up..."
    if ! pulumi up --yes; then
        print_error "Error en pulumi up. Revisa los logs anteriores."
        exit 1
    fi
    
    # Obtener outputs
    print_info "Obteniendo outputs de Pulumi..."
    local cluster_name=$(pulumi stack output clusterName 2>/dev/null || true)
    local backend_repo=$(pulumi stack output backendRepoUrl 2>/dev/null || true)
    local frontend_repo=$(pulumi stack output frontendRepoUrl 2>/dev/null || true)
    local db_host=$(pulumi stack output dbHost 2>/dev/null || true)
    local region=$(pulumi stack output region 2>/dev/null || true)
    
    print_info "Valores obtenidos:"
    print_info "  Cluster: $cluster_name"
    print_info "  Backend Repo: $backend_repo"
    print_info "  Frontend Repo: $frontend_repo"
    print_info "  DB Host: $db_host"
    print_info "  Región: $region"
    
    cd ..
    
    # Exportar para uso en otras funciones
    export DEPLOY_CLUSTER_NAME="$cluster_name"
    export DEPLOY_BACKEND_REPO="$backend_repo"
    export DEPLOY_FRONTEND_REPO="$frontend_repo"
    export DEPLOY_DB_HOST="$db_host"
    export DEPLOY_REGION="$region"
}

# Función para configurar kubectl
setup_kubectl() {
    local cluster_name=$1
    local region=$2
    
    print_step "Configurando kubectl..."
    
    print_info "Obteniendo credenciales para cluster: $cluster_name en región: $region"
    aws eks update-kubeconfig --name $cluster_name --region $region
    
    print_info "kubectl configurado correctamente ✓"
    
    # Verificar conexión
    print_info "Verificando conexión al cluster..."
    kubectl get nodes
}

# Función para configurar autenticación Docker con ECR
setup_docker_auth() {
    local region=$1
    local repo=$2
    
    print_info "Configurando autenticación de Docker con ECR..."
    export DOCKER_CONFIG="${HOME}/.docker"
    mkdir -p "$DOCKER_CONFIG"
    
    aws ecr get-login-password --region $region | docker login --username AWS --password-stdin ${repo%/*} || {
        print_error "Error al autenticar con ECR. Intentando método alternativo..."
        aws ecr get-login --region $region --no-include-email | bash
    }
}

# Función para construir y subir imagen del backend
build_and_push_backend() {
    local backend_repo=$1
    local region=$2
    
    print_step "Construyendo y subiendo imagen del backend..."
    
    setup_docker_auth "$region" "$backend_repo"
    
    print_info "Construyendo imagen del backend..."
    cd backend
    docker build -t $backend_repo:latest .
    print_info "Subiendo imagen del backend..."
    docker push $backend_repo:latest
    cd ..
    
    print_info "Imagen del backend construida y subida correctamente ✓"
}

# Función para construir y subir imagen del frontend
build_and_push_frontend() {
    local frontend_repo=$1
    local region=$2
    local backend_url=$3
    
    print_step "Construyendo y subiendo imagen del frontend..."
    
    setup_docker_auth "$region" "$frontend_repo"
    
    print_info "Construyendo imagen del frontend con URL del backend: $backend_url/api"
    cd frontend
    docker build --build-arg VITE_API_URL=$backend_url/api -t $frontend_repo:latest .
    print_info "Subiendo imagen del frontend..."
    docker push $frontend_repo:latest
    cd ..
    
    print_info "Imagen del frontend construida y subida correctamente ✓"
}

# Función para configurar secretos
setup_secrets() {
    local db_host=$1
    
    print_step "Configurando secretos..."
    
    # Crear namespace si no existe
    print_info "Creando namespace 'todo' si no existe..."
    kubectl create namespace todo 2>/dev/null || true
    
    # Crear secret para ECR (para poder hacer pull de imágenes)
    print_info "Configurando secret para ECR..."
    aws ecr get-login-password --region ${DEPLOY_REGION} | docker login --username AWS --password-stdin ${DEPLOY_BACKEND_REPO%/*}
    
    local ecr_token=$(aws ecr get-authorization-token --region ${DEPLOY_REGION} --query 'authorizationData[0].authorizationToken' --output text)
    
    kubectl delete secret ecr-registry-secret -n todo 2>/dev/null || true
    
    kubectl create secret docker-registry ecr-registry-secret \
        --docker-server=https://$(echo ${DEPLOY_BACKEND_REPO%/*} | cut -d'/' -f1) \
        --docker-username=AWS \
        --docker-password="$ecr_token" \
        -n todo
    
    print_info "Secretos configurados correctamente ✓"
}

# Función para desplegar aplicación
deploy_application() {
    local backend_repo=$1
    local frontend_repo=$2
    local db_host=$3
    
    print_step "Desplegando aplicación en Kubernetes..."
    
    # Esperar a que los nodos estén listos
    print_info "Esperando a que los nodos estén listos..."
    kubectl wait --for=condition=Ready nodes --all --timeout=600s
    
    # Crear directorio temporal
    mkdir -p k8s-temp
    cp -r k8s-aws/* k8s-temp/
    
    # Actualizar URLs de imágenes y DB host
    print_info "Actualizando URLs de imágenes..."
    sed -i "s|IMAGE_PLACEHOLDER_BACKEND|$backend_repo:latest|g" k8s-temp/backend-deployment.yaml
    sed -i "s|IMAGE_PLACEHOLDER_FRONTEND|$frontend_repo:latest|g" k8s-temp/frontend-deployment.yaml
    
    # Actualizar URL del backend en el ConfigMap del frontend (será actualizado después con la URL del LoadBalancer)
    print_info "Actualizando URL del backend en frontend..."
    # Por ahora dejar placeholder, luego se actualizará con la URL real del LoadBalancer
    sed -i "s|http://PLACEHOLDER/api|http://PLACEHOLDER_BACKEND_LB/api|g" k8s-temp/frontend-configmap.yaml
    
    # Actualizar DB host (codificar en base64 para el secret)
    print_info "Actualizando host de base de datos..."
    local db_host_base64=$(echo -n "$db_host" | base64 | tr -d '\n')
    # Reemplazar el valor base64 del placeholder en la línea mysql-host
    sed -i "s|mysql-host: REJfSE9TVF9QTEFDRUhPTERFUg==|mysql-host: $db_host_base64|g" k8s-temp/mysql-secret.yaml
    
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

# Función para obtener la URL del LoadBalancer del backend
get_backend_loadbalancer_url() {
    print_step "Obteniendo URL del LoadBalancer del backend..." >&2
    
    local max_attempts=30
    local attempt=1
    local backend_lb_hostname=""
    
    while [ $attempt -le $max_attempts ]; do
        backend_lb_hostname=$(kubectl get service backend -n todo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        
        if [ -n "$backend_lb_hostname" ] && [ "$backend_lb_hostname" != "null" ]; then
            print_info "URL del LoadBalancer del backend obtenida: $backend_lb_hostname" >&2
            # El puerto se obtiene del servicio (normalmente 8000 para el backend)
            local backend_port=$(kubectl get service backend -n todo -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "8000")
            echo "http://${backend_lb_hostname}:${backend_port}"
            return 0
        fi
        
        print_info "Esperando a que el LoadBalancer del backend esté listo... (intento $attempt/$max_attempts)" >&2
        sleep 10
        attempt=$((attempt + 1))
    done
    
    print_error "No se pudo obtener la URL del LoadBalancer del backend después de $max_attempts intentos" >&2
    return 1
}

# Función para sembrar la base de datos
seed_database() {
    print_step "Sembrando la base de datos..."
    
    # Esperar a que el backend esté completamente listo
    print_info "Esperando a que el backend esté listo..."
    sleep 10
    
    # Ejecutar migraciones
    print_info "Ejecutando migraciones..."
    kubectl exec deployment/backend -n todo -- php artisan migrate --force
    
    # Sembrar la base de datos
    print_info "Sembrando la base de datos..."
    kubectl exec deployment/backend -n todo -- php artisan db:seed --class=TaskSeeder --force
    
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
    
    # Obtener IP del LoadBalancer
    local lb_ip=$(kubectl get service frontend -n todo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -n "$lb_ip" ]; then
        print_info "LoadBalancer hostname: $lb_ip"
        print_info "URL de la aplicación: http://$lb_ip"
        export DEPLOY_APP_URL="http://$lb_ip"
    else
        print_warning "El LoadBalancer aún no tiene IP asignada. Espera unos minutos."
    fi
    
    print_info "Verificación completada ✓"
}

# Función para mostrar información final
show_final_info() {
    local cluster_name=$1
    local region=$2
    local app_url=$3
    
    echo ""
    echo "=============================================="
    print_info "¡DESPLIEGUE COMPLETADO EXITOSAMENTE! 🎉"
    echo "=============================================="
    echo ""
    
    print_info "Información del cluster:"
    echo "  - Nombre: $cluster_name"
    echo "  - Región: $region"
    echo ""
    
    if [ -n "$app_url" ]; then
        print_info "🌐 Tu aplicación está disponible en:"
        echo "  $app_url"
        echo ""
    fi
    
    print_info "Comandos útiles:"
    echo "  kubectl get pods -n todo"
    echo "  kubectl get hpa -n todo"
    echo "  kubectl get services -n todo"
    echo ""
    
    print_info "Para pruebas de carga:"
    echo "  kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- sh -c 'while true; do wget -q -O- $app_url; done'"
    echo ""
    
    print_warning "IMPORTANTE: Para eliminar todos los recursos:"
    echo "  cd pulumi-aws && pulumi destroy"
    echo ""
    
    print_info "Recuerda que AWS Free Tier te permite correr esto por 12 meses."
    print_warning "Los nodos t3.small NO son gratis - verifica tu facturación."
}

# Función principal
main() {
    # Verificar prerrequisitos
    check_prerequisites
    echo ""
    
    # Verificar autenticación AWS
    check_aws_auth
    echo ""
    
    # Configurar Pulumi
    setup_pulumi
    echo ""
    
    # Desplegar infraestructura
    deploy_infrastructure
    echo ""
    
    # Configurar kubectl
    setup_kubectl "$DEPLOY_CLUSTER_NAME" "$DEPLOY_REGION"
    echo ""
    
    # Construir y subir imagen del backend
    build_and_push_backend "$DEPLOY_BACKEND_REPO" "$DEPLOY_REGION"
    echo ""
    
    # Construir imagen temporal del frontend (se reconstruirá después con la URL correcta)
    build_and_push_frontend "$DEPLOY_FRONTEND_REPO" "$DEPLOY_REGION" "http://PLACEHOLDER"
    echo ""
    
    # Configurar secretos
    setup_secrets "$DEPLOY_DB_HOST"
    echo ""
    
    # Desplegar aplicación
    deploy_application "$DEPLOY_BACKEND_REPO" "$DEPLOY_FRONTEND_REPO" "$DEPLOY_DB_HOST"
    echo ""
    
    # Obtener URL del LoadBalancer del backend
    print_info "Esperando a que el LoadBalancer del backend esté disponible..."
    sleep 15
    local backend_url=$(get_backend_loadbalancer_url)
    
    if [ -z "$backend_url" ]; then
        print_error "No se pudo obtener la URL del backend. Continuando con despliegue temporal..."
        backend_url="http://PLACEHOLDER"
    fi
    
    echo ""
    
    # Reconstruir frontend con la URL correcta del backend
    print_info "Reconstruyendo frontend con URL correcta del backend: $backend_url"
    build_and_push_frontend "$DEPLOY_FRONTEND_REPO" "$DEPLOY_REGION" "$backend_url"
    echo ""
    
    # Actualizar el deployment del frontend con la nueva imagen
    print_info "Actualizando deployment del frontend con la nueva imagen..."
    kubectl rollout restart deployment/frontend -n todo
    print_info "Esperando rollout del frontend (puede tomar algunos minutos)..."
    # Esperar máximo 2 minutos, si no completa, continuar de todas formas
    kubectl rollout status deployment/frontend -n todo --timeout=120s || {
        print_warning "El rollout del frontend está tomando más tiempo del esperado."
        print_info "Los pods antiguos siguen funcionando. El nuevo rollout continuará en segundo plano."
    }
    echo ""
    
    # Sembrar la base de datos
    seed_database
    echo ""
    
    # Verificar despliegue
    verify_deployment
    echo ""
    
    # Mostrar información final
    show_final_info "$DEPLOY_CLUSTER_NAME" "$DEPLOY_REGION" "$DEPLOY_APP_URL"
}

# Ejecutar función principal
main "$@"

