#!/bin/bash

# Script de monitoreo en tiempo real para el cluster To-Do App
# Monitorea pods, recursos y logs en tiempo real

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
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

# Función para mostrar banner
show_banner() {
    clear
    echo -e "${CYAN}=============================================="
    echo -e "📊 MONITOREO EN TIEMPO REAL - To-Do App"
    echo -e "==============================================${NC}"
    echo ""
}

# Función para monitorear pods
monitor_pods() {
    print_step "Monitoreando Pods (Ctrl+C para salir)"
    echo ""
    
    while true; do
        clear
        show_banner
        print_info "Estado de Pods - $(date)"
        echo ""
        kubectl get pods -n todo -o wide
        echo ""
        print_info "Presiona Ctrl+C para salir del monitoreo"
        sleep 5
    done
}

# Función para monitorear recursos
monitor_resources() {
    print_step "Monitoreando Recursos (Ctrl+C para salir)"
    echo ""
    
    while true; do
        clear
        show_banner
        print_info "Uso de Recursos - $(date)"
        echo ""
        
        print_info "Recursos de Nodos:"
        kubectl top nodes 2>/dev/null || print_warning "Metrics server no disponible"
        echo ""
        
        print_info "Recursos de Pods:"
        kubectl top pods -n todo 2>/dev/null || print_warning "Metrics server no disponible"
        echo ""
        
        print_info "Presiona Ctrl+C para salir del monitoreo"
        sleep 10
    done
}

# Función para monitorear logs
monitor_logs() {
    print_step "Monitoreando Logs en Tiempo Real"
    echo ""
    
    print_info "Pods disponibles:"
    kubectl get pods -n todo --no-headers | awk '{print $1}'
    echo ""
    
    read -p "Selecciona el pod para monitorear logs: " pod_name
    
    if [ -n "$pod_name" ]; then
        print_info "Monitoreando logs de $pod_name (Ctrl+C para salir)..."
        kubectl logs -n todo $pod_name -f
    else
        print_warning "No se especificó un pod"
    fi
}

# Función para monitorear eventos
monitor_events() {
    print_step "Monitoreando Eventos (Ctrl+C para salir)"
    echo ""
    
    while true; do
        clear
        show_banner
        print_info "Eventos Recientes - $(date)"
        echo ""
        kubectl get events -n todo --sort-by='.lastTimestamp' | tail -15
        echo ""
        print_info "Presiona Ctrl+C para salir del monitoreo"
        sleep 5
    done
}

# Función para monitoreo completo
monitor_all() {
    print_step "Monitoreo Completo (Ctrl+C para salir)"
    echo ""
    
    while true; do
        clear
        show_banner
        print_info "Monitoreo Completo - $(date)"
        echo ""
        
        print_info "Estado de Pods:"
        kubectl get pods -n todo
        echo ""
        
        print_info "Servicios:"
        kubectl get services -n todo
        echo ""
        
        print_info "HPA:"
        kubectl get hpa -n todo
        echo ""
        
        print_info "Recursos de Pods:"
        kubectl top pods -n todo 2>/dev/null || print_warning "Metrics server no disponible"
        echo ""
        
        print_info "Eventos Recientes:"
        kubectl get events -n todo --sort-by='.lastTimestamp' | tail -5
        echo ""
        
        print_info "Presiona Ctrl+C para salir del monitoreo"
        sleep 10
    done
}

# Función para mostrar menú
show_menu() {
    echo -e "${CYAN}Selecciona el tipo de monitoreo:${NC}"
    echo ""
    echo "1. 🐳 Monitorear pods"
    echo "2. 📊 Monitorear recursos"
    echo "3. 📝 Monitorear logs en tiempo real"
    echo "4. 📅 Monitorear eventos"
    echo "5. 🔄 Monitoreo completo"
    echo "6. ❌ Salir"
    echo ""
}

# Función principal
main() {
    show_banner
    
    # Verificar conexión a kubectl
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "No se puede conectar al cluster de Kubernetes"
        print_warning "Asegúrate de que kubectl esté configurado correctamente"
        exit 1
    fi
    
    print_info "Conectado al cluster exitosamente"
    echo ""
    
    while true; do
        show_menu
        read -p "Selecciona una opción (1-6): " choice
        
        case $choice in
            1)
                monitor_pods
                ;;
            2)
                monitor_resources
                ;;
            3)
                monitor_logs
                ;;
            4)
                monitor_events
                ;;
            5)
                monitor_all
                ;;
            6)
                print_info "¡Hasta luego! 👋"
                exit 0
                ;;
            *)
                print_error "Opción inválida. Por favor, selecciona una opción del 1 al 6."
                sleep 2
                ;;
        esac
        
        show_banner
    done
}

# Ejecutar función principal
main "$@"
