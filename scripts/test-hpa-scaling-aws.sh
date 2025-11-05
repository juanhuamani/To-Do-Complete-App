#!/bin/bash

# Script mejorado para pruebas de escalado horizontal en AWS EKS
# Similar a test-hpa-scaling-improved.sh pero adaptado para AWS

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
echo -e "📈 PRUEBA DE ESCALADO HORIZONTAL (HPA) - AWS EKS"
echo -e "==============================================${NC}"
echo ""

# Verificar conexión
if ! kubectl cluster-info >/dev/null 2>&1; then
    print_error "No se puede conectar al cluster de Kubernetes"
    print_info "Verifica que kubectl esté configurado correctamente:"
    print_info "  aws eks update-kubeconfig --name CLUSTER_NAME --region us-east-1"
    exit 1
fi

print_success "Conectado al cluster exitosamente"
echo ""

# Función para mostrar estado actual
show_current_state() {
    print_step "Estado Actual"
    echo ""
    
    print_info "HPA configurado:"
    kubectl get hpa -n todo 2>/dev/null || print_warning "HPA no encontrado en namespace todo"
    echo ""
    
    print_info "Pods Backend:"
    kubectl get pods -n todo -l app=backend 2>/dev/null || print_warning "Pods backend no encontrados"
    echo ""
    
    print_info "Pods Frontend:"
    kubectl get pods -n todo -l app=frontend 2>/dev/null || print_warning "Pods frontend no encontrados"
    echo ""
    
    print_info "Métricas de recursos:"
    kubectl top pods -n todo 2>/dev/null || print_warning "Metrics server no disponible"
    echo ""
    
    print_info "Nodos:"
    kubectl get nodes 2>/dev/null || print_warning "No se pueden obtener nodos"
    echo ""
}

# Función para escalar con timeout
scale_with_timeout() {
    local deployment=$1
    local replicas=$2
    local timeout_seconds=${3:-120}
    
    print_info "Escalando $deployment a $replicas réplicas..."
    kubectl scale deployment $deployment -n todo --replicas=$replicas
    
    print_info "Esperando escalado (timeout: ${timeout_seconds}s)..."
    
    # Usar timeout para evitar que se quede colgado
    if timeout $timeout_seconds kubectl rollout status deployment/$deployment -n todo 2>/dev/null; then
        print_success "$deployment escalado exitosamente"
    else
        print_warning "$deployment: timeout alcanzado, verificando estado..."
        kubectl get pods -n todo -l app=$deployment
        print_warning "Continuando con el siguiente paso..."
    fi
    echo ""
}

# Función para escalar a mínimo
scale_to_minimum() {
    print_step "Escalando a Mínimo (3 réplicas)"
    echo ""
    
    scale_with_timeout "backend" 3 120
    scale_with_timeout "frontend" 3 120
    
    print_success "Escalado a mínimo completado"
    echo ""
}

# Función para escalar para prueba
scale_for_test() {
    print_step "Escalando para Prueba (Backend: 8, Frontend: 5) - Para forzar 3er nodo"
    echo ""
    
    # Escalar a más pods para forzar que se necesite un 3er nodo
    # Con 2 nodos t3.small (2 vCPU, 2GB RAM cada uno), podemos tener ~6-8 pods por nodo
    # Escalando a 8 pods de backend + 5 de frontend, necesitaremos un 3er nodo
    scale_with_timeout "backend" 8 180
    scale_with_timeout "frontend" 5 180
    
    print_success "Escalado de prueba completado"
    echo ""
    print_info "Con 8 pods de backend + 5 de frontend, debería necesitarse un 3er nodo"
    echo ""
}

# Función para monitorear durante la prueba
monitor_during_test() {
    print_step "Monitoreando durante la Prueba"
    echo ""
    
    print_info "Estado del HPA durante la prueba:"
    kubectl get hpa -n todo
    echo ""
    
    print_info "Pods durante la prueba:"
    kubectl get pods -n todo -l app=backend
    kubectl get pods -n todo -l app=frontend
    echo ""
    
    print_info "Métricas durante la prueba:"
    kubectl top pods -n todo 2>/dev/null || print_warning "Metrics server no disponible"
    echo ""
    
    print_info "Nodos durante la prueba:"
    kubectl get nodes
    local node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    print_info "Total de nodos: $node_count (esperado: 3 para autoscaling completo)"
    kubectl top nodes 2>/dev/null || print_warning "Métricas de nodos no disponibles"
    echo ""
    
    # Verificar pods en Pending (esperando nodos)
    local pending_pods=$(kubectl get pods -n todo --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)
    if [ "$pending_pods" -gt 0 ]; then
        print_warning "⚠️  Hay $pending_pods pods en estado Pending (esperando que se agregue nodo)"
        kubectl get pods -n todo --field-selector=status.phase=Pending
    fi
    echo ""
    
    print_info "Eventos recientes:"
    kubectl get events -n todo --sort-by='.lastTimestamp' | tail -5
    echo ""
}

# Función para volver al mínimo
scale_back_to_minimum() {
    print_step "Volviendo al Mínimo (3 réplicas)"
    echo ""
    
    scale_with_timeout "backend" 3 120
    scale_with_timeout "frontend" 3 120
    
    print_success "Vuelta al mínimo completada"
    echo ""
}

# Función para verificar estado de pods
check_pods_ready() {
    local deployment=$1
    local expected_replicas=$2
    
    print_info "Verificando estado de $deployment..."
    local ready_pods=$(kubectl get pods -n todo -l app=$deployment --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    local total_pods=$(kubectl get pods -n todo -l app=$deployment --no-headers 2>/dev/null | wc -l)
    
    print_info "$deployment: $ready_pods/$total_pods pods listos (esperado: $expected_replicas)"
    
    if [ "$ready_pods" -eq "$expected_replicas" ] && [ "$total_pods" -eq "$expected_replicas" ]; then
        return 0
    else
        return 1
    fi
}

# Función principal
main() {
    print_info "Iniciando prueba de escalado horizontal..."
    echo ""
    
    # Mostrar estado inicial
    show_current_state
    
    print_warning "¿Quieres continuar con la prueba de escalado? (y/N)"
    read -p "Confirmar: " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        print_info "Prueba cancelada"
        exit 0
    fi
    
    # Paso 1: Asegurar mínimo
    scale_to_minimum
    
    # Verificar que el mínimo esté listo
    print_info "Verificando estado mínimo..."
    check_pods_ready "backend" 3
    check_pods_ready "frontend" 3
    show_current_state
    
    # Paso 2: Escalar para prueba
    scale_for_test
    
    # Verificar que la prueba esté lista
    print_info "Verificando estado de prueba..."
    check_pods_ready "backend" 8
    check_pods_ready "frontend" 5
    show_current_state
    
    # Monitorear si se agrega un 3er nodo
    print_info "Esperando a que el Cluster Autoscaler agregue un 3er nodo (puede tomar 2-5 minutos)..."
    local initial_nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    print_info "Nodos iniciales: $initial_nodes"
    
    # Esperar hasta 5 minutos para que aparezca el 3er nodo
    local max_wait=300  # 5 minutos
    local waited=0
    while [ $waited -lt $max_wait ]; do
        sleep 10
        waited=$((waited + 10))
        local current_nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
        
        if [ "$current_nodes" -gt "$initial_nodes" ]; then
            print_success "✅ ¡Nuevo nodo agregado! Total: $current_nodes nodos"
            kubectl get nodes
            break
        fi
        
        if [ $((waited % 30)) -eq 0 ]; then
            print_info "Esperando... (${waited}s/${max_wait}s) - Nodos actuales: $current_nodes"
            # Verificar si hay pods en Pending (esperando nodos)
            local pending_pods=$(kubectl get pods -n todo --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)
            if [ "$pending_pods" -gt 0 ]; then
                print_info "Pods en Pending: $pending_pods (esperando que se agregue nodo)"
            fi
        fi
    done
    
    if [ "$waited" -ge "$max_wait" ]; then
        print_warning "Timeout esperando el 3er nodo. Verificando estado..."
        local final_nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
        print_info "Nodos finales: $final_nodes"
        kubectl get nodes
        kubectl get pods -n todo -o wide
    fi
    
    # Paso 3: Monitorear
    print_info "Monitoreando por 30 segundos..."
    sleep 30
    monitor_during_test
    
    # Paso 4: Volver al mínimo
    print_warning "¿Quieres volver al mínimo (3 réplicas)? (y/N)"
    read -p "Confirmar: " scale_back
    
    if [ "$scale_back" = "y" ] || [ "$scale_back" = "Y" ]; then
        scale_back_to_minimum
        
        # Verificar estado final
        print_info "Verificando estado final..."
        check_pods_ready "backend" 3
        check_pods_ready "frontend" 3
        show_current_state
    else
        print_info "Manteniendo escalado de prueba activo"
    fi
    
    print_success "🎉 Prueba de escalado horizontal completada"
    echo ""
    
    print_info "Resumen final:"
    kubectl get hpa -n todo
    kubectl get pods -n todo -l app=backend
    kubectl get pods -n todo -l app=frontend
    kubectl get nodes
}

# Ejecutar función principal
main "$@"

