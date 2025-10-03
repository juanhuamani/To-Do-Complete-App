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

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}To-Do Complete App - Herramientas de Desarrollo${NC}"
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  start-ports    Configurar port-forward para desarrollo"
    echo "  stop-ports     Detener todos los port-forwards"
    echo "  logs-frontend  Ver logs del frontend en tiempo real"
    echo "  logs-backend   Ver logs del backend en tiempo real"
    echo "  logs-mysql     Ver logs de MySQL en tiempo real"
    echo "  status         Mostrar estado de todos los pods"
    echo "  restart-backend Reiniciar el deployment del backend"
    echo "  restart-frontend Reiniciar el deployment del frontend"
    echo "  shell-backend  Abrir shell en el pod del backend"
    echo "  shell-mysql    Conectar a MySQL"
    echo "  seed           Poblar base de datos con datos de ejemplo"
    echo "  reset-db       Reiniciar base de datos (migrate + seed)"
    echo "  scale-backend  Escalar backend manualmente"
    echo "  scale-frontend Escalar frontend manualmente"
    echo "  hpa-status     Ver estado del escalamiento automático"
    echo "  clean          Limpiar todos los recursos"
    echo "  help           Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 start-ports"
    echo "  $0 logs-backend"
    echo "  $0 status"
}

# Función para configurar port-forward
start_ports() {
    print_status "Configurando port-forward..."
    
    # Detener port-forwards existentes
    pkill -f "kubectl port-forward" >/dev/null 2>&1 || true
    
    # Iniciar port-forwards
    kubectl port-forward service/frontend 3000:3000 &
    kubectl port-forward service/backend 8000:8000 &
    
    sleep 2
    
    print_success "Port-forward configurado:"
    echo "• Frontend: http://localhost:3000"
    echo "• Backend: http://localhost:8000"
    echo ""
    print_warning "Los port-forwards están ejecutándose en segundo plano"
    print_warning "Usa '$0 stop-ports' para detenerlos"
}

# Función para detener port-forwards
stop_ports() {
    print_status "Deteniendo port-forwards..."
    pkill -f "kubectl port-forward" >/dev/null 2>&1 || true
    print_success "Port-forwards detenidos"
}

# Función para ver logs del frontend
logs_frontend() {
    print_status "Mostrando logs del frontend..."
    kubectl logs -f deployment/frontend
}

# Función para ver logs del backend
logs_backend() {
    print_status "Mostrando logs del backend..."
    kubectl logs -f deployment/backend
}

# Función para ver logs de MySQL
logs_mysql() {
    print_status "Mostrando logs de MySQL..."
    kubectl logs -f statefulset/mysql
}

# Función para mostrar estado
show_status() {
    print_status "Estado de la aplicación:"
    echo ""
    
    echo -e "${BLUE}Pods:${NC}"
    kubectl get pods -o wide
    echo ""
    
    echo -e "${BLUE}Servicios:${NC}"
    kubectl get services
    echo ""
    
    echo -e "${BLUE}Ingress:${NC}"
    kubectl get ingress
    echo ""
    
    echo -e "${BLUE}Volúmenes:${NC}"
    kubectl get pvc
    echo ""
    
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "N/A")
    echo -e "${BLUE}Minikube IP:${NC} $MINIKUBE_IP"
}

# Función para reiniciar backend
restart_backend() {
    print_status "Reiniciando backend..."
    kubectl rollout restart deployment/backend
    kubectl rollout status deployment/backend
    print_success "Backend reiniciado"
}

# Función para reiniciar frontend
restart_frontend() {
    print_status "Reiniciando frontend..."
    kubectl rollout restart deployment/frontend
    kubectl rollout status deployment/frontend
    print_success "Frontend reiniciado"
}

# Función para abrir shell en backend
shell_backend() {
    print_status "Abriendo shell en el backend..."
    kubectl exec -it deployment/backend -- /bin/bash
}

# Función para conectar a MySQL
shell_mysql() {
    print_status "Conectando a MySQL..."
    kubectl exec -it mysql-0 -- mysql -uuser -ppass mydb
}

# Función para limpiar recursos
clean_all() {
    print_warning "Esto eliminará TODOS los recursos de Kubernetes"
    read -p "¿Estás seguro? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Limpiando recursos..."
        
        pkill -f "kubectl port-forward" >/dev/null 2>&1 || true
        
        kubectl delete all --all >/dev/null 2>&1 || true
        kubectl delete pvc --all >/dev/null 2>&1 || true
        kubectl delete configmap --all >/dev/null 2>&1 || true
        kubectl delete secret --all >/dev/null 2>&1 || true
        kubectl delete ingress --all >/dev/null 2>&1 || true
        
        print_success "Recursos limpiados"
    else
        print_status "Operación cancelada"
    fi
}

# Función para reconstruir imágenes
rebuild_images() {
    print_status "Reconstruyendo imágenes..."
    
    eval "$(minikube docker-env)"
    ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
    
    docker build -t todo-complete-backend:local "$ROOT_DIR/backend"
    docker build -t todo-complete-frontend:local "$ROOT_DIR/frontend"
    
    print_success "Imágenes reconstruidas"
    
    print_status "Reiniciando deployments..."
    kubectl rollout restart deployment/backend
    kubectl rollout restart deployment/frontend
    
    print_success "Deployments reiniciados con nuevas imágenes"
}

# Función para ejecutar comandos de Laravel
laravel_command() {
    local command="$1"
    print_status "Ejecutando: php artisan $command"
    kubectl exec deployment/backend -- php artisan "$command"
}

# Función para poblar la base de datos
seed_database() {
    print_status "Poblando la base de datos con datos de ejemplo..."
    kubectl exec deployment/backend -- php artisan db:seed --class=TaskSeeder
    
    # Verificar que se crearon las tareas
    local task_count=$(kubectl exec mysql-0 -- mysql -uuser -ppass mydb -e "SELECT COUNT(*) FROM tasks;" 2>/dev/null | tail -1)
    
    if [ "$task_count" -gt 0 ]; then
        print_success "Base de datos poblada con $task_count tareas de ejemplo"
    else
        print_warning "No se pudieron crear las tareas de ejemplo"
    fi
}

# Función para reiniciar la base de datos
reset_database() {
    print_warning "Esto eliminará todos los datos existentes"
    read -p "¿Estás seguro? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Reiniciando base de datos..."
        
        # Ejecutar migraciones frescas
        kubectl exec deployment/backend -- php artisan migrate:fresh
        
        # Poblar con datos de ejemplo
        kubectl exec deployment/backend -- php artisan db:seed --class=TaskSeeder
        
        print_success "Base de datos reiniciada con datos de ejemplo"
    else
        print_status "Operación cancelada"
    fi
}

# Función para escalar backend manualmente
scale_backend() {
    print_status "Escalando backend..."
    read -p "¿Cuántas réplicas quieres? (1-10): " replicas
    
    if [[ $replicas =~ ^[1-9]$|^10$ ]]; then
        kubectl scale deployment backend --replicas=$replicas
        print_success "Backend escalado a $replicas réplicas"
        
        print_status "Esperando a que los pods estén listos..."
        kubectl rollout status deployment/backend
    else
        print_error "Número inválido. Usa un número entre 1 y 10."
    fi
}

# Función para escalar frontend manualmente
scale_frontend() {
    print_status "Escalando frontend..."
    read -p "¿Cuántas réplicas quieres? (1-5): " replicas
    
    if [[ $replicas =~ ^[1-5]$ ]]; then
        kubectl scale deployment frontend --replicas=$replicas
        print_success "Frontend escalado a $replicas réplicas"
        
        print_status "Esperando a que los pods estén listos..."
        kubectl rollout status deployment/frontend
    else
        print_error "Número inválido. Usa un número entre 1 y 5."
    fi
}

# Función para ver estado del HPA
hpa_status() {
    print_status "Estado del escalamiento automático (HPA):"
    echo ""
    
    echo -e "${BLUE}Backend HPA:${NC}"
    kubectl get hpa backend-hpa -o wide
    echo ""
    
    echo -e "${BLUE}Frontend HPA:${NC}"
    kubectl get hpa frontend-hpa -o wide
    echo ""
    
    echo -e "${BLUE}Descripción detallada:${NC}"
    kubectl describe hpa backend-hpa
    echo ""
    kubectl describe hpa frontend-hpa
}

# Función principal
main() {
    case "${1:-help}" in
        "start-ports")
            start_ports
            ;;
        "stop-ports")
            stop_ports
            ;;
        "logs-frontend")
            logs_frontend
            ;;
        "logs-backend")
            logs_backend
            ;;
        "logs-mysql")
            logs_mysql
            ;;
        "status")
            show_status
            ;;
        "restart-backend")
            restart_backend
            ;;
        "restart-frontend")
            restart_frontend
            ;;
        "shell-backend")
            shell_backend
            ;;
        "shell-mysql")
            shell_mysql
            ;;
        "clean")
            clean_all
            ;;
        "rebuild")
            rebuild_images
            ;;
        "cache-clear")
            laravel_command "cache:clear"
            ;;
        "config-cache")
            laravel_command "config:cache"
            ;;
        "route-cache")
            laravel_command "route:cache"
            ;;
        "migrate")
            laravel_command "migrate"
            ;;
        "seed")
            seed_database
            ;;
        "reset-db")
            reset_database
            ;;
        "scale-backend")
            scale_backend
            ;;
        "scale-frontend")
            scale_frontend
            ;;
        "hpa-status")
            hpa_status
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Ejecutar función principal
main "$@"
