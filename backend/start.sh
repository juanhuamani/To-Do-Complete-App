#!/bin/bash
set -e

echo "🚀 Iniciando contenedor Laravel..."
echo "📦 Configurando cache de Laravel..."

# Configurar cache de configuración
php artisan config:cache

# Configurar cache de rutas
php artisan route:cache

echo "✅ Cache configurado correctamente"
echo "🌟 Iniciando servidor Laravel..."

# Iniciar servidor
php artisan serve --host=0.0.0.0 --port=8000

