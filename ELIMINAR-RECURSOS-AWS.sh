#!/bin/bash

# Script para eliminar todos los recursos de AWS y evitar consumo de créditos

set -e

echo "=============================================="
echo "⚠️  ELIMINACIÓN DE RECURSOS AWS"
echo "=============================================="
echo ""
echo "Este script eliminará:"
echo "  - Cluster EKS"
echo "  - Base de datos RDS"
echo "  - Load Balancers"
echo "  - Instancias EC2 (nodos)"
echo "  - Repositorios ECR"
echo "  - VPC y Security Groups"
echo ""
read -p "¿Estás seguro que quieres eliminar TODOS los recursos? (escribe 'SI' para confirmar): " confirmacion

if [ "$confirmacion" != "SI" ]; then
    echo "Operación cancelada."
    exit 0
fi

echo ""
echo "Eliminando recursos con Pulumi..."
echo ""

cd pulumi-aws

# Configurar passphrase
export PULUMI_CONFIG_PASSPHRASE="MiPasswordSeguro123!"

# Eliminar infraestructura
echo "Ejecutando pulumi destroy..."
pulumi destroy --yes

echo ""
echo "=============================================="
echo "✅ RECURSOS ELIMINADOS"
echo "=============================================="
echo ""
echo "Todos los recursos han sido eliminados."
echo "Ya no se consumirán créditos de AWS."
echo ""
echo "Nota: Algunos recursos pueden tardar varios minutos en eliminarse completamente."
echo "Verifica en la consola de AWS que todo se haya eliminado."

