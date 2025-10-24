Write-Host "Aplicando todas las configuraciones de Kubernetes..." -ForegroundColor Green

# Aplicar namespace
Write-Host "Aplicando namespace..." -ForegroundColor Yellow
kubectl apply -f namespace.yaml

# Aplicar secrets
Write-Host "Aplicando secrets..." -ForegroundColor Yellow
kubectl apply -f mysql-secret.yaml
kubectl apply -f docker-registry-secret.yaml

# Aplicar configmaps
Write-Host "Aplicando configmaps..." -ForegroundColor Yellow
kubectl apply -f backend-configmap.yaml
kubectl apply -f frontend-configmap.yaml

# Aplicar deployments
Write-Host "Aplicando deployments..." -ForegroundColor Yellow
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml

# Aplicar services
Write-Host "Aplicando services..." -ForegroundColor Yellow
kubectl apply -f backend-service.yaml
kubectl apply -f frontend-service.yaml

# Aplicar HPA
Write-Host "Aplicando HPA..." -ForegroundColor Yellow
kubectl apply -f hpa.yaml

# Aplicar Ingress
Write-Host "Aplicando Ingress..." -ForegroundColor Yellow
kubectl apply -f ingress.yaml

Write-Host "Todas las configuraciones han sido aplicadas exitosamente!" -ForegroundColor Green
Write-Host "La aplicación está disponible en: http://34.144.246.195" -ForegroundColor Cyan
