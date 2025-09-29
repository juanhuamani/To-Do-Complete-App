#!/usr/bin/env bash
set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para verificar prerrequisitos
check_prerequisites() {
    print_status "Verificando prerrequisitos..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado"
        exit 1
    fi
    
    if ! command -v minikube &> /dev/null; then
        print_error "Minikube no está instalado"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl no está instalado"
        exit 1
    fi
    
    print_success "Todos los prerrequisitos están instalados"
}

# Función para verificar que Minikube esté ejecutándose
check_minikube() {
    print_status "Verificando estado de Minikube..."
    
    if ! minikube status | grep -q "Running"; then
        print_status "Iniciando Minikube..."
        minikube start
    fi
    
    print_success "Minikube está ejecutándose"
}

# Función para limpiar recursos existentes
cleanup_existing() {
    print_status "Limpiando recursos existentes..."
    
    kubectl delete all --all >/dev/null 2>&1 || true
    kubectl delete pvc --all >/dev/null 2>&1 || true
    kubectl delete configmap --all >/dev/null 2>&1 || true
    kubectl delete secret --all >/dev/null 2>&1 || true
    kubectl delete ingress --all >/dev/null 2>&1 || true
    
    print_success "Recursos limpiados"
}

# Función para construir imágenes
build_images() {
    print_status "Configurando entorno Docker para Minikube..."
    eval "$(minikube docker-env)"
    
    ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
    
    print_status "Construyendo imagen del backend..."
    docker build -t todo-complete-backend:local "$ROOT_DIR/backend"
    
    print_status "Construyendo imagen del frontend..."
    docker build -t todo-complete-frontend:local "$ROOT_DIR/frontend"
    
    print_success "Imágenes construidas correctamente"
}

# Función para aplicar manifiestos
apply_manifests() {
    ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
    
    print_status "Aplicando manifiestos de Kubernetes..."
    
    # MySQL
    kubectl apply -f "$ROOT_DIR/k8s/mysql-secret.yaml"
    kubectl apply -f "$ROOT_DIR/k8s/mysql-pvc.yaml"
    kubectl apply -f "$ROOT_DIR/k8s/mysql-service.yaml"
    kubectl apply -f "$ROOT_DIR/k8s/mysql-statefulset.yaml"
    
    # Backend
    kubectl apply -f "$ROOT_DIR/k8s/backend-configmap.yaml"
    kubectl apply -f "$ROOT_DIR/k8s/backend-service.yaml"
    kubectl apply -f "$ROOT_DIR/k8s/backend-deployment.yaml"
    
    # Frontend
    kubectl apply -f "$ROOT_DIR/k8s/frontend-service.yaml"
    kubectl apply -f "$ROOT_DIR/k8s/frontend-deployment.yaml"
    
    # Ingress
    print_status "Habilitando Ingress de Minikube..."
    minikube addons enable ingress >/dev/null 2>&1 || true
    kubectl apply -f "$ROOT_DIR/k8s/ingress.yaml"
    
    print_success "Manifiestos aplicados correctamente"
}

# Función para esperar a que los pods estén listos
wait_for_pods() {
    print_status "Esperando a que los pods estén listos..."
    
    # Esperar a MySQL
    kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s
    
    # Esperar a Backend (incluye initContainers)
    kubectl wait --for=condition=ready pod -l app=backend --timeout=300s
    
    # Esperar a Frontend
    kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s
    
    print_success "Todos los pods están listos"
}

# Función para poblar la base de datos
seed_database() {
    print_status "Poblando la base de datos con datos de ejemplo..."
    
    # Ejecutar el seeder de tareas
    kubectl exec deployment/backend -- php artisan db:seed --class=TaskSeeder >/dev/null 2>&1
    
    # Verificar que se crearon las tareas
    local task_count=$(kubectl exec mysql-0 -- mysql -uuser -ppass mydb -e "SELECT COUNT(*) FROM tasks;" 2>/dev/null | tail -1)
    
    if [ "$task_count" -gt 0 ]; then
        print_success "Base de datos poblada con $task_count tareas de ejemplo"
    else
        print_warning "No se pudieron crear las tareas de ejemplo"
    fi
}

# Función para mostrar información de acceso
show_access_info() {
    MINIKUBE_IP=$(minikube ip)
    
    print_success "¡Aplicación desplegada correctamente!"
    echo ""
    echo -e "${BLUE}Información de acceso:${NC}"
    echo "• Minikube IP: $MINIKUBE_IP"
    echo "• Frontend: http://localhost:3000 (con port-forward)"
    echo "• Backend API: http://localhost:8000/api (con port-forward)"
    echo "• Ingress: http://$MINIKUBE_IP (requiere tunnel)"
    echo ""
    echo -e "${YELLOW}Para acceder a la aplicación:${NC}"
    echo "1. Configura port-forward:"
    echo "   kubectl port-forward service/frontend 3000:3000 &"
    echo "   kubectl port-forward service/backend 8000:8000 &"
    echo ""
    echo "2. Abre tu navegador en: http://localhost:3000"
    echo ""
    echo -e "${YELLOW}Comandos útiles:${NC}"
    echo "• Ver pods: kubectl get pods"
    echo "• Ver logs: kubectl logs -f deployment/frontend"
    echo "• Ver servicios: kubectl get services"
    echo "• Detener app: kubectl delete all --all"
}

# Función principal
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  To-Do Complete App - Kubernetes      ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    check_prerequisites
    check_minikube
    cleanup_existing
    build_images
    apply_manifests
    wait_for_pods
    seed_database
    show_access_info
    
    echo ""
    print_success "¡Despliegue completado exitosamente! 🎉"
}

# Ejecutar función principal
main "$@" 

