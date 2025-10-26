#!/bin/bash

# Script de comandos rápidos para el cluster To-Do App
# Comandos útiles para gestión rápida del cluster

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

# Función para mostrar ayuda
show_help() {
    echo -e "${CYAN}Comandos rápidos para el cluster To-Do App${NC}"
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  status      - Estado general del cluster"
    echo "  pods        - Lista de pods"
    echo "  services    - Lista de servicios"
    echo "  logs        - Logs de todos los pods"
    echo "  restart     - Reiniciar todos los pods"
    echo "  scale       - Escalar pods (ej: scale backend 3)"
    echo "  url         - Mostrar URL de la aplicación"
    echo "  health      - Verificar salud de la aplicación"
    echo "  resources   - Uso de recursos"
    echo "  events      - Eventos recientes"
    echo "  menu        - Abrir menú interactivo"
    echo "  help        - Mostrar esta ayuda"
    echo ""
}

# Función para mostrar estado general
show_status() {
    print_step "Estado General del Cluster"
    echo ""
    
    print_info "Pods en el namespace todo:"
    kubectl get pods -n todo
    echo ""
    
    print_info "Servicios:"
    kubectl get services -n todo
    echo ""
    
    print_info "Ingress:"
    kubectl get ingress -n todo
    echo ""
    
    print_info "HPA:"
    kubectl get hpa -n todo
    echo ""
}

# Función para mostrar pods
show_pods() {
    print_step "Pods del Namespace 'todo'"
    kubectl get pods -n todo -o wide
}

# Función para mostrar servicios
show_services() {
    print_step "Servicios del Namespace 'todo'"
    kubectl get services -n todo
    echo ""
    kubectl get ingress -n todo
}

# Función para mostrar logs
show_logs() {
    print_step "Logs de Todos los Pods"
    echo ""
    
    for pod in $(kubectl get pods -n todo --no-headers | awk '{print $1}'); do
        echo -e "${CYAN}=== Logs de $pod ===${NC}"
        kubectl logs -n todo $pod --tail=20
        echo ""
    done
}

# Función para reiniciar pods
restart_pods() {
    print_step "Reiniciando Pods"
    echo ""
    
    print_info "Reiniciando deployment del backend..."
    kubectl rollout restart deployment/backend -n todo
    
    print_info "Reiniciando deployment del frontend..."
    kubectl rollout restart deployment/frontend -n todo
    
    print_info "Esperando a que los pods estén listos..."
    kubectl rollout status deployment/backend -n todo
    kubectl rollout status deployment/frontend -n todo
    
    print_info "Pods reiniciados exitosamente"
}

# Función para escalar pods
scale_pods() {
    local deployment=$1
    local replicas=$2
    
    if [ -z "$deployment" ] || [ -z "$replicas" ]; then
        print_error "Uso: $0 scale <deployment> <replicas>"
        print_info "Ejemplo: $0 scale backend 3"
        print_warning "NOTA: El mínimo recomendado es 3 réplicas"
        exit 1
    fi
    
    # Verificar que no sea menos de 3 réplicas
    if [ "$replicas" -lt 3 ]; then
        print_warning "⚠️  Advertencia: Menos de 3 réplicas puede afectar la disponibilidad"
        print_warning "¿Estás seguro de que quieres escalar a $replicas réplicas? (y/N)"
        read -p "Confirmar: " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            print_info "Escalado cancelado"
            exit 0
        fi
    fi
    
    print_step "Escalando $deployment a $replicas réplicas"
    kubectl scale deployment $deployment -n todo --replicas=$replicas
    
    print_info "Esperando a que el escalado se complete..."
    kubectl rollout status deployment/$deployment -n todo
    
    print_info "Escalado completado"
}

# Función para mostrar URL
show_url() {
    print_step "URL de la Aplicación"
    echo ""
    
    ingress_ip=$(kubectl get ingress todo-ingress -n todo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$ingress_ip" ]; then
        print_info "🌐 Tu aplicación está disponible en:"
        echo -e "${CYAN}  http://$ingress_ip${NC}"
    else
        print_warning "El Ingress aún no tiene IP asignada"
        print_info "Ejecuta 'kubectl get ingress -n todo' para verificar el estado"
    fi
}

# Función para verificar salud
check_health() {
    print_step "Verificando Salud de la Aplicación"
    echo ""
    
    print_info "Estado de los pods:"
    kubectl get pods -n todo
    echo ""
    
    print_info "Verificando conectividad..."
    backend_pod=$(kubectl get pods -n todo -l app=backend --no-headers | head -1 | awk '{print $1}')
    if [ -n "$backend_pod" ]; then
        print_info "Probando backend desde $backend_pod..."
        kubectl exec -n todo $backend_pod -- curl -s http://localhost:8000/api/health || print_warning "Backend no responde"
    fi
    
    print_info "Verificando base de datos..."
    if [ -n "$backend_pod" ]; then
        kubectl exec -n todo $backend_pod -- php artisan tinker --execute="DB::connection()->getPdo(); echo 'DB OK';" || print_warning "Base de datos no responde"
    fi
}

# Función para mostrar recursos
show_resources() {
    print_step "Uso de Recursos"
    echo ""
    
    print_info "Recursos de nodos:"
    kubectl top nodes 2>/dev/null || print_warning "Metrics server no disponible"
    echo ""
    
    print_info "Recursos de pods:"
    kubectl top pods -n todo 2>/dev/null || print_warning "Metrics server no disponible"
}

# Función para mostrar eventos
show_events() {
    print_step "Eventos Recientes"
    kubectl get events -n todo --sort-by='.lastTimestamp' | tail -10
}

# Función para abrir menú interactivo
open_menu() {
    print_info "Abriendo menú interactivo..."
    bash scripts/cluster-menu.sh
}

# Función principal
main() {
    case "${1:-help}" in
        "status")
            show_status
            ;;
        "pods")
            show_pods
            ;;
        "services")
            show_services
            ;;
        "logs")
            show_logs
            ;;
        "restart")
            restart_pods
            ;;
        "scale")
            scale_pods "$2" "$3"
            ;;
        "url")
            show_url
            ;;
        "health")
            check_health
            ;;
        "resources")
            show_resources
            ;;
        "events")
            show_events
            ;;
        "menu")
            open_menu
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Ejecutar función principal
main "$@"
