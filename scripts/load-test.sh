#!/bin/bash

# Script para realizar pruebas de carga y demostrar escalamiento automático

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con color
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
    echo -e "${BLUE}To-Do Complete App - Load Testing Script${NC}"
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  light        Prueba de carga ligera (10 requests/segundo por 30 segundos)"
    echo "  medium       Prueba de carga media (50 requests/segundo por 60 segundos)"
    echo "  heavy        Prueba de carga pesada (100 requests/segundo por 120 segundos)"
    echo "  custom       Prueba personalizada (configurable)"
    echo "  monitor      Monitorear recursos durante la prueba"
    echo "  stop         Detener todas las pruebas de carga"
    echo "  help         Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 light"
    echo "  $0 medium"
    echo "  $0 custom --rate 30 --duration 45"
}

# Función para verificar prerrequisitos
check_prerequisites() {
    print_status "Verificando prerrequisitos..."
    
    if ! command -v curl &> /dev/null; then
        print_error "curl no está instalado"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl no está instalado"
        exit 1
    fi
    
    # Verificar que el backend esté disponible
    if ! kubectl get deployment backend &> /dev/null; then
        print_error "Backend deployment no encontrado"
        exit 1
    fi
    
    print_success "Prerrequisitos verificados"
}

# Función para obtener la URL del backend
get_backend_url() {
    # Intentar port-forward primero
    if kubectl get pods -l app=backend --field-selector=status.phase=Running | grep -q backend; then
        echo "http://localhost:8000"
    else
        print_error "Backend no está disponible"
        exit 1
    fi
}

# Función para realizar prueba de carga ligera
light_load_test() {
    print_status "Iniciando prueba de carga ligera..."
    print_warning "10 requests/segundo por 30 segundos"
    
    local backend_url=$(get_backend_url)
    local duration=30
    local rate=10
    
    print_status "URL del backend: $backend_url"
    print_status "Duración: ${duration}s, Rate: ${rate} req/s"
    
    # Crear archivo temporal para los resultados
    local results_file="/tmp/load_test_results_$(date +%s).txt"
    
    # Ejecutar prueba de carga
    for ((i=1; i<=duration; i++)); do
        for ((j=1; j<=rate; j++)); do
            {
                start_time=$(date +%s.%N)
                response=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" "$backend_url/api/tasks")
                end_time=$(date +%s.%N)
                echo "$response,$start_time,$end_time" >> "$results_file"
            } &
        done
        
        # Esperar 1 segundo
        sleep 1
        
        # Mostrar progreso
        if ((i % 5 == 0)); then
            print_status "Progreso: ${i}/${duration} segundos"
        fi
    done
    
    # Esperar a que terminen todos los requests
    wait
    
    # Analizar resultados
    analyze_results "$results_file"
}

# Función para realizar prueba de carga media
medium_load_test() {
    print_status "Iniciando prueba de carga media..."
    print_warning "50 requests/segundo por 60 segundos"
    
    local backend_url=$(get_backend_url)
    local duration=60
    local rate=50
    
    print_status "URL del backend: $backend_url"
    print_status "Duración: ${duration}s, Rate: ${rate} req/s"
    
    local results_file="/tmp/load_test_results_$(date +%s).txt"
    
    for ((i=1; i<=duration; i++)); do
        for ((j=1; j<=rate; j++)); do
            {
                start_time=$(date +%s.%N)
                response=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" "$backend_url/api/tasks")
                end_time=$(date +%s.%N)
                echo "$response,$start_time,$end_time" >> "$results_file"
            } &
        done
        
        sleep 1
        
        if ((i % 10 == 0)); then
            print_status "Progreso: ${i}/${duration} segundos"
        fi
    done
    
    wait
    analyze_results "$results_file"
}

# Función para realizar prueba de carga pesada
heavy_load_test() {
    print_status "Iniciando prueba de carga pesada..."
    print_warning "100 requests/segundo por 120 segundos"
    
    local backend_url=$(get_backend_url)
    local duration=120
    local rate=100
    
    print_status "URL del backend: $backend_url"
    print_status "Duración: ${duration}s, Rate: ${rate} req/s"
    
    local results_file="/tmp/load_test_results_$(date +%s).txt"
    
    for ((i=1; i<=duration; i++)); do
        for ((j=1; j<=rate; j++)); do
            {
                start_time=$(date +%s.%N)
                response=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" "$backend_url/api/tasks")
                end_time=$(date +%s.%N)
                echo "$response,$start_time,$end_time" >> "$results_file"
            } &
        done
        
        sleep 1
        
        if ((i % 20 == 0)); then
            print_status "Progreso: ${i}/${duration} segundos"
        fi
    done
    
    wait
    analyze_results "$results_file"
}

# Función para realizar prueba personalizada
custom_load_test() {
    local rate=10
    local duration=30
    
    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --rate)
                rate="$2"
                shift 2
                ;;
            --duration)
                duration="$2"
                shift 2
                ;;
            *)
                print_error "Argumento desconocido: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_status "Iniciando prueba de carga personalizada..."
    print_warning "${rate} requests/segundo por ${duration} segundos"
    
    local backend_url=$(get_backend_url)
    local results_file="/tmp/load_test_results_$(date +%s).txt"
    
    for ((i=1; i<=duration; i++)); do
        for ((j=1; j<=rate; j++)); do
            {
                start_time=$(date +%s.%N)
                response=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" "$backend_url/api/tasks")
                end_time=$(date +%s.%N)
                echo "$response,$start_time,$end_time" >> "$results_file"
            } &
        done
        
        sleep 1
        
        if ((i % 5 == 0)); then
            print_status "Progreso: ${i}/${duration} segundos"
        fi
    done
    
    wait
    analyze_results "$results_file"
}

# Función para analizar resultados
analyze_results() {
    local results_file="$1"
    
    if [[ ! -f "$results_file" ]]; then
        print_error "Archivo de resultados no encontrado"
        return 1
    fi
    
    print_status "Analizando resultados..."
    
    # Contar total de requests
    local total_requests=$(wc -l < "$results_file")
    
    # Contar códigos de respuesta
    local success_count=$(awk -F',' '$1 == "200" {count++} END {print count+0}' "$results_file")
    local error_count=$((total_requests - success_count))
    
    # Calcular tiempo promedio de respuesta
    local avg_time=$(awk -F',' '{sum+=$2} END {print sum/NR}' "$results_file")
    
    # Calcular tiempo máximo de respuesta
    local max_time=$(awk -F',' 'BEGIN{max=0} $2>max{max=$2} END {print max}' "$results_file")
    
    # Mostrar resultados
    echo ""
    print_success "=== RESULTADOS DE LA PRUEBA DE CARGA ==="
    echo -e "${BLUE}Total de requests:${NC} $total_requests"
    echo -e "${GREEN}Requests exitosos:${NC} $success_count"
    echo -e "${RED}Requests con error:${NC} $error_count"
    echo -e "${BLUE}Tiempo promedio de respuesta:${NC} ${avg_time}s"
    echo -e "${YELLOW}Tiempo máximo de respuesta:${NC} ${max_time}s"
    
    # Calcular porcentaje de éxito
    local success_rate=$((success_count * 100 / total_requests))
    echo -e "${GREEN}Tasa de éxito:${NC} ${success_rate}%"
    
    # Limpiar archivo temporal
    rm -f "$results_file"
}

# Función para monitorear recursos
monitor_resources() {
    print_status "Monitoreando recursos del cluster..."
    echo ""
    
    while true; do
        clear
        echo -e "${BLUE}=== MONITOR DE RECURSOS ===${NC}"
        echo ""
        
        echo -e "${YELLOW}Pods:${NC}"
        kubectl get pods -o wide
        echo ""
        
        echo -e "${YELLOW}HPA Status:${NC}"
        kubectl get hpa
        echo ""
        
        echo -e "${YELLOW}Recursos por Pod:${NC}"
        kubectl top pods 2>/dev/null || echo "Métricas no disponibles"
        echo ""
        
        echo -e "${YELLOW}Recursos por Nodo:${NC}"
        kubectl top nodes 2>/dev/null || echo "Métricas no disponibles"
        echo ""
        
        echo -e "${BLUE}Presiona Ctrl+C para salir${NC}"
        sleep 5
    done
}

# Función para detener pruebas de carga
stop_load_tests() {
    print_status "Deteniendo todas las pruebas de carga..."
    
    # Matar procesos de curl en background
    pkill -f "curl.*api/tasks" 2>/dev/null || true
    
    print_success "Pruebas de carga detenidas"
}

# Función principal
main() {
    case "${1:-help}" in
        "light")
            check_prerequisites
            light_load_test
            ;;
        "medium")
            check_prerequisites
            medium_load_test
            ;;
        "heavy")
            check_prerequisites
            heavy_load_test
            ;;
        "custom")
            check_prerequisites
            shift
            custom_load_test "$@"
            ;;
        "monitor")
            monitor_resources
            ;;
        "stop")
            stop_load_tests
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Ejecutar función principal
main "$@"
