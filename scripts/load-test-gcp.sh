#!/bin/bash

# Script para pruebas de carga en Google Cloud GKE
# Demuestra el autoscaling de la aplicación

set -e

echo "=============================================="
echo "🧪 PRUEBAS DE CARGA - Autoscaling Demo"
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

# Función para verificar si hey está instalado
check_hey() {
    if ! command -v hey >/dev/null 2>&1; then
        print_warning "Hey no está instalado. Instalando..."
        
        if command -v go >/dev/null 2>&1; then
            go install github.com/rakyll/hey@latest
        else
            print_error "Go no está instalado. Instala Go desde https://golang.org/dl/"
            print_info "Alternativamente, puedes instalar hey manualmente:"
            print_info "  go install github.com/rakyll/hey@latest"
            exit 1
        fi
    fi
}

# Función para obtener la URL de la aplicación
get_app_url() {
    local ingress_ip=$(kubectl get ingress todo-ingress -n todo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -z "$ingress_ip" ]; then
        print_error "No se pudo obtener la IP del Ingress"
        print_info "Verifica que el Ingress esté funcionando:"
        print_info "  kubectl get ingress -n todo"
        exit 1
    fi
    
    echo "http://$ingress_ip"
}

# Función para mostrar estado inicial
show_initial_state() {
    print_step "Estado inicial de la aplicación"
    
    print_info "Pods actuales:"
    kubectl get pods -n todo -o wide
    
    print_info "HPA actual:"
    kubectl get hpa -n todo
    
    print_info "Recursos de los nodos:"
    kubectl top nodes 2>/dev/null || print_warning "Metrics server no disponible"
}

# Función para ejecutar prueba de carga
run_load_test() {
    local app_url=$1
    local duration=${2:-60}
    local concurrency=${3:-10}
    
    print_step "Ejecutando prueba de carga"
    print_info "URL: $app_url"
    print_info "Duración: ${duration}s"
    print_info "Concurrencia: $concurrency"
    print_info "Endpoint: /api/tasks"
    
    echo ""
    print_warning "Iniciando prueba de carga en 5 segundos..."
    sleep 5
    
    # Ejecutar prueba de carga
    hey -n 1000 -c $concurrency -t $duration "$app_url/api/tasks" &
    local hey_pid=$!
    
    # Monitorear durante la prueba
    print_info "Monitoreando durante la prueba..."
    for i in $(seq 1 $duration); do
        echo -n "."
        sleep 1
        
        # Mostrar estado cada 10 segundos
        if [ $((i % 10)) -eq 0 ]; then
            echo ""
            print_info "Tiempo: ${i}s"
            kubectl get hpa -n todo
            kubectl get pods -n todo --no-headers | wc -l | xargs echo "Pods totales:"
        fi
    done
    
    echo ""
    print_info "Esperando a que termine la prueba de carga..."
    wait $hey_pid
    
    print_info "Prueba de carga completada ✓"
}

# Función para mostrar estado final
show_final_state() {
    print_step "Estado final de la aplicación"
    
    print_info "Pods después de la prueba:"
    kubectl get pods -n todo -o wide
    
    print_info "HPA después de la prueba:"
    kubectl get hpa -n todo
    
    print_info "Recursos de los nodos después de la prueba:"
    kubectl top nodes 2>/dev/null || print_warning "Metrics server no disponible"
}

# Función para mostrar métricas de autoscaling
show_scaling_metrics() {
    print_step "Métricas de autoscaling"
    
    print_info "Historial de escalado del backend:"
    kubectl describe hpa backend-hpa -n todo | grep -A 10 "Events:"
    
    print_info "Historial de escalado del frontend:"
    kubectl describe hpa frontend-hpa -n todo | grep -A 10 "Events:"
}

# Función para limpiar (opcional)
cleanup() {
    print_step "Limpieza (opcional)"
    
    print_warning "¿Quieres esperar a que los pods se reduzcan automáticamente?"
    print_info "Esto puede tomar varios minutos debido a la ventana de estabilización del HPA."
    
    read -p "¿Esperar a que se reduzcan los pods? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Esperando a que los pods se reduzcan..."
        print_info "Esto puede tomar 5-10 minutos..."
        
        while true; do
            local current_pods=$(kubectl get pods -n todo --no-headers | wc -l)
            local target_pods=$(kubectl get hpa -n todo -o jsonpath='{.items[0].status.desiredReplicas}')
            
            if [ "$current_pods" -eq "$target_pods" ]; then
                print_info "Los pods se han reducido al número objetivo ✓"
                break
            fi
            
            print_info "Pods actuales: $current_pods, Objetivo: $target_pods"
            sleep 30
        done
    fi
}

# Función para mostrar resumen
show_summary() {
    print_step "Resumen de la demostración"
    
    echo ""
    print_info "✅ Lo que has demostrado:"
    echo "  - Autoscaling horizontal de pods (HPA)"
    echo "  - Escalado automático basado en CPU y memoria"
    echo "  - Distribución de carga entre múltiples pods"
    echo "  - Recuperación automática después de la carga"
    echo ""
    
    print_info "📊 Métricas observadas:"
    echo "  - Número de pods antes y después de la carga"
    echo "  - Utilización de CPU y memoria"
    echo "  - Tiempo de respuesta de la aplicación"
    echo "  - Comportamiento del HPA"
    echo ""
    
    print_info "🎯 Beneficios del autoscaling:"
    echo "  - Escalado automático según la demanda"
    echo "  - Optimización de recursos y costos"
    echo "  - Alta disponibilidad y resistencia"
    echo "  - Gestión automática de la carga"
    echo ""
}

# Función principal
main() {
    # Verificar prerrequisitos
    check_hey
    
    # Obtener URL de la aplicación
    local app_url=$(get_app_url)
    print_info "URL de la aplicación: $app_url"
    
    # Verificar que la aplicación esté funcionando
    print_info "Verificando que la aplicación esté funcionando..."
    if ! curl -s "$app_url/api/hello" >/dev/null; then
        print_error "La aplicación no está respondiendo"
        print_info "Verifica que esté desplegada correctamente:"
        print_info "  kubectl get pods -n todo"
        exit 1
    fi
    
    print_info "Aplicación funcionando correctamente ✓"
    echo ""
    
    # Mostrar estado inicial
    show_initial_state
    echo ""
    
    # Ejecutar prueba de carga
    run_load_test "$app_url" 60 15
    echo ""
    
    # Mostrar estado final
    show_final_state
    echo ""
    
    # Mostrar métricas de autoscaling
    show_scaling_metrics
    echo ""
    
    # Limpiar (opcional)
    cleanup
    echo ""
    
    # Mostrar resumen
    show_summary
}

# Ejecutar función principal
main "$@"