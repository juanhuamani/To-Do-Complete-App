#!/bin/bash

echo "Aplicando todas las configuraciones de Kubernetes..."

# Aplicar namespace
kubectl apply -f namespace.yaml

# Aplicar secrets
kubectl apply -f mysql-secret.yaml
kubectl apply -f docker-registry-secret.yaml

# Aplicar configmaps
kubectl apply -f backend-configmap.yaml
kubectl apply -f frontend-configmap.yaml

# Aplicar deployments
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml

# Aplicar services
kubectl apply -f backend-service.yaml
kubectl apply -f frontend-service.yaml

# Aplicar HPA
kubectl apply -f hpa.yaml

# Aplicar Ingress
kubectl apply -f ingress.yaml

echo "Todas las configuraciones han sido aplicadas exitosamente!"
echo "La aplicación está disponible en: http://34.144.246.195"
