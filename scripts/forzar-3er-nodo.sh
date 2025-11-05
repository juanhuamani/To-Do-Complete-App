#!/bin/bash

# Script para forzar que el Cluster Autoscaler agregue un 3er nodo
# Crea pods con muchos recursos para que no quepan en 2 nodos

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

print_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

print_header() {
    echo -e "${CYAN}=============================================="
    echo -e "$1"
    echo -e "==============================================${NC}"
}

print_header "🚀 Forzar 3er Nodo - Cluster Autoscaler"

# Verificar conexión
if ! kubectl cluster-info >/dev/null 2>&1; then
    print_error "No se puede conectar al cluster de Kubernetes"
    exit 1
fi

print_info "Estado inicial de nodos:"
kubectl get nodes
initial_nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
print_info "Nodos actuales: $initial_nodes"

if [ "$initial_nodes" -ge 3 ]; then
    print_success "Ya tienes 3 o más nodos!"
    exit 0
fi

echo ""
print_info "Creando pods con recursos altos para forzar 3er nodo..."
print_warning "Esto creará pods temporales que consumen muchos recursos"
echo ""

read -p "¿Continuar? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Operación cancelada"
    exit 0
fi

# Crear Deployment temporal con pods que consumen muchos recursos
# Cada pod pedirá 500m CPU y 512Mi memoria
# Con 10 pods = 5000m CPU (5 cores) y 5120Mi memoria
# Esto no cabe en 2 nodos t3.small (2 vCPU cada uno = 4 cores totales)

print_info "Creando deployment temporal con pods de alto consumo..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stress-high-resources
  namespace: todo
spec:
  replicas: 10
  selector:
    matchLabels:
      app: stress-high-resources
  template:
    metadata:
      labels:
        app: stress-high-resources
    spec:
      containers:
      - name: stress
        image: polinux/stress:latest
        command: ["stress"]
        args: ["--cpu", "1", "--timeout", "300s"]
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
EOF

print_success "Deployment creado ✓"
echo ""

print_info "Esperando a que los pods se creen..."
sleep 10

print_info "Estado de pods:"
kubectl get pods -n todo -l app=stress-high-resources

pending_pods=$(kubectl get pods -n todo -l app=stress-high-resources --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)
print_info "Pods en Pending: $pending_pods"

if [ "$pending_pods" -gt 0 ]; then
    print_warning "⚠️  Hay $pending_pods pods en Pending - esto debería forzar un 3er nodo"
fi

echo ""
print_info "Monitoreando nodos (esperando hasta 5 minutos para que aparezca el 3er nodo)..."
max_wait=300
waited=0

while [ $waited -lt $max_wait ]; do
    sleep 10
    waited=$((waited + 10))
    current_nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    
    if [ "$current_nodes" -gt "$initial_nodes" ]; then
        print_success "✅ ¡Nuevo nodo agregado! Total: $current_nodes nodos"
        kubectl get nodes
        break
    fi
    
    if [ $((waited % 30)) -eq 0 ]; then
        print_info "Esperando... (${waited}s/${max_wait}s) - Nodos actuales: $current_nodes"
        pending=$(kubectl get pods -n todo -l app=stress-high-resources --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)
        if [ "$pending" -gt 0 ]; then
            print_info "Pods en Pending: $pending (esperando nodo)"
        fi
    fi
done

if [ "$waited" -ge "$max_wait" ]; then
    print_warning "Timeout esperando el 3er nodo"
    final_nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    print_info "Nodos finales: $final_nodes"
    kubectl get nodes
    kubectl get pods -n todo -l app=stress-high-resources -o wide
fi

echo ""
print_info "Estado final:"
kubectl get nodes
echo ""
print_info "Pods de stress:"
kubectl get pods -n todo -l app=stress-high-resources

echo ""
print_warning "¿Quieres eliminar los pods de stress? (y/n)"
read -p "Confirmar: " cleanup
if [[ $cleanup =~ ^[Yy]$ ]]; then
    print_info "Eliminando deployment de stress..."
    kubectl delete deployment stress-high-resources -n todo --ignore-not-found=true
    print_success "Deployment eliminado ✓"
else
    print_info "Manteniendo pods de stress. Para eliminarlos manualmente:"
    print_info "  kubectl delete deployment stress-high-resources -n todo"
fi

echo ""
print_success "Operación completada"

