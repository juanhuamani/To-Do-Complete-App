#!/bin/bash

echo "Aplicando todas las configuraciones de Kubernetes para AWS..."

# Aplicar namespace
kubectl apply -f namespace.yaml

# Aplicar secrets
kubectl apply -f mysql-secret.yaml
kubectl apply -f ecr-registry-secret.yaml

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

echo "Todas las configuraciones han sido aplicadas exitosamente!"
echo "Obtén la URL del LoadBalancer con: kubectl get service frontend -n todo"

