#!/bin/bash

# Script para monitorear el autoscaling en tiempo real
# Muestra HPA, pods, nodos y métricas en un dashboard en terminal

echo "======================================"
echo "Monitor de Autoscaling - To-Do App"
echo "======================================"
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Verificar que kubectl está configurado
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: kubectl no está configurado correctamente${NC}"
    exit 1
fi

# Función para mostrar estado
show_dashboard() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Dashboard de Autoscaling - To-Do App EKS           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Timestamp
    echo -e "${YELLOW}Última actualización: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
    
    # HPA Status
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Horizontal Pod Autoscaler (HPA)                            ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    kubectl get hpa -n todo-app 2>/dev/null || echo -e "${RED}Error obteniendo HPA${NC}"
    echo ""
    
    # Pods Status
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Estado de Pods                                             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    kubectl get pods -n todo-app -o wide 2>/dev/null || echo -e "${RED}Error obteniendo pods${NC}"
    
    # Contar pods por estado
    RUNNING=$(kubectl get pods -n todo-app --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    PENDING=$(kubectl get pods -n todo-app --no-headers 2>/dev/null | grep -c "Pending" || echo "0")
    FAILED=$(kubectl get pods -n todo-app --no-headers 2>/dev/null | grep -c "Error\|Failed\|CrashLoop" || echo "0")
    
    echo ""
    echo -e "  ${GREEN}✓ Running: $RUNNING${NC}  ${YELLOW}⏳ Pending: $PENDING${NC}  ${RED}✗ Failed: $FAILED${NC}"
    echo ""
    
    # Nodos Status
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Estado de Nodos                                            ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    kubectl get nodes -o wide 2>/dev/null || echo -e "${RED}Error obteniendo nodos${NC}"
    
    # Contar nodos
    READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "Ready" || echo "0")
    echo ""
    echo -e "  ${GREEN}✓ Nodos Ready: $READY_NODES${NC}"
    echo ""
    
    # Métricas de Recursos
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Métricas de Recursos (CPU/Memoria)                         ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "${CYAN}Pods:${NC}"
    kubectl top pods -n todo-app 2>/dev/null || echo -e "${YELLOW}Esperando métricas del Metrics Server...${NC}"
    echo ""
    
    echo -e "${CYAN}Nodos:${NC}"
    kubectl top nodes 2>/dev/null || echo -e "${YELLOW}Esperando métricas del Metrics Server...${NC}"
    echo ""
    
    # Cluster Autoscaler Status
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Cluster Autoscaler                                         ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    CA_POD=$(kubectl get pods -n kube-system -l app=cluster-autoscaler --no-headers 2>/dev/null | head -n1 | awk '{print $1}')
    
    if [ -n "$CA_POD" ]; then
        echo -e "${GREEN}✓ Cluster Autoscaler está corriendo${NC}"
        echo ""
        echo -e "${CYAN}Últimos logs:${NC}"
        kubectl logs -n kube-system $CA_POD --tail=5 2>/dev/null | grep -E "scale_up|scale_down|ScalingGroup|Node" || echo "Sin actividad reciente"
    else
        echo -e "${RED}✗ Cluster Autoscaler no encontrado${NC}"
    fi
    echo ""
    
    # Eventos Recientes
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Eventos Recientes (últimos 5)                              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    kubectl get events -n todo-app --sort-by='.lastTimestamp' 2>/dev/null | tail -6 | head -5 || echo -e "${RED}Error obteniendo eventos${NC}"
    echo ""
    
    # Footer
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Comandos útiles:                                           ║${NC}"
    echo -e "${CYAN}║    kubectl describe hpa backend-hpa -n todo-app             ║${NC}"
    echo -e "${CYAN}║    kubectl logs -f deployment/cluster-autoscaler -n kube-... ║${NC}"
    echo -e "${CYAN}║    kubectl get events -n kube-system | grep cluster-auto... ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}🔄 Actualizando cada 10 segundos... (Ctrl+C para salir)${NC}"
}

# Loop infinito
echo "Iniciando monitor de autoscaling..."
echo "Presiona Ctrl+C para detener"
sleep 2

while true; do
    show_dashboard
    sleep 10
done

