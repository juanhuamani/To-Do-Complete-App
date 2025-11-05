#!/bin/bash

# Script para aumentar nodos y probar autoscaling

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() {
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

print_header() {
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}==============================================${NC}"
}

# Configuración
MIN_NODES=${1:-3}   # Número mínimo de nodos (default: 3)
MAX_NODES=${2:-5}   # Número máximo de nodos (default: 5)
DESIRED_NODES=${3:-3}  # Número deseado de nodos (default: 3)

print_header "🔧 Aumentar Nodos para Probar Autoscaling"

# Verificar que estamos en el directorio correcto
if [ ! -d "pulumi-aws" ]; then
    print_error "Este script debe ejecutarse desde la raíz del proyecto"
    exit 1
fi

cd pulumi-aws

print_info "Configuración actual:"
pulumi config get minNodes 2>/dev/null || echo "  minNodes: (no configurado)"
pulumi config get maxNodes 2>/dev/null || echo "  maxNodes: (no configurado)"
pulumi config get desiredNodes 2>/dev/null || echo "  desiredNodes: (no configurado)"
echo ""

print_info "Nueva configuración:"
echo "  minNodes: $MIN_NODES"
echo "  maxNodes: $MAX_NODES"
echo "  desiredNodes: $DESIRED_NODES"
echo ""

print_warning "⚠️  Esto aumentará los costos de AWS"
print_warning "   - 3 nodos t3.small: ~\$45/mes"
print_warning "   - 5 nodos t3.small: ~\$75/mes"
echo ""

read -p "¿Continuar? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Operación cancelada"
    exit 0
fi

print_info "Configurando nodos..."
pulumi config set minNodes $MIN_NODES
pulumi config set maxNodes $MAX_NODES
pulumi config set desiredNodes $DESIRED_NODES

print_success "Configuración actualizada ✓"
echo ""

print_info "Verificando configuración:"
pulumi config | grep -E "(minNodes|maxNodes|desiredNodes)" || true
echo ""

print_info "Aplicando cambios con pulumi up..."
print_warning "Esto tomará ~10-15 minutos para agregar los nodos"
echo ""

read -p "¿Ejecutar pulumi up ahora? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Configuración guardada. Ejecuta 'pulumi up' cuando estés listo"
    exit 0
fi

# Configurar passphrase si existe
if [ -n "$PULUMI_CONFIG_PASSPHRASE" ]; then
    export PULUMI_CONFIG_PASSPHRASE
fi

print_info "Ejecutando pulumi up..."
pulumi up --yes

print_success "✅ Nodos actualizados"
echo ""

print_info "Verificar nodos:"
echo "  kubectl get nodes"
echo ""

print_info "Monitorear escalamiento:"
echo "  watch -n 5 'kubectl get nodes && echo \"\" && kubectl get pods -n todo -o wide'"
echo ""

print_info "Para volver a configuración original:"
echo "  pulumi config set minNodes 2"
echo "  pulumi config set maxNodes 3"
echo "  pulumi config set desiredNodes 2"
echo "  pulumi up"
echo ""

