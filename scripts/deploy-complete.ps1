# Script completo para desplegar To-Do App en Google Cloud GKE
# ¡GRATIS con los $300 de crédito de Google Cloud!

param(
    [switch]$SkipInfrastructure = $false,
    [switch]$SkipImages = $false,
    [switch]$SkipDeployment = $false
)

# Configurar colores
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Blue = "Blue"
$Cyan = "Cyan"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Red
}

function Write-Step {
    param([string]$Message)
    Write-Host "[STEP] $Message" -ForegroundColor $Blue
}

# Función para verificar prerrequisitos
function Test-Prerequisites {
    Write-Step "Verificando prerrequisitos..."
    
    $missingTools = @()
    
    if (!(Get-Command gcloud -ErrorAction SilentlyContinue)) {
        $missingTools += "Google Cloud SDK"
    }
    
    if (!(Get-Command pulumi -ErrorAction SilentlyContinue)) {
        $missingTools += "Pulumi"
    }
    
    if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
        $missingTools += "kubectl"
    }
    
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        $missingTools += "Docker"
    }
    
    if ($missingTools.Count -gt 0) {
        Write-Error "Herramientas faltantes:"
        foreach ($tool in $missingTools) {
            Write-Host "  - $tool"
        }
        Write-Host ""
        Write-Host "Instala las herramientas faltantes y vuelve a ejecutar el script."
        exit 1
    }
    
    Write-Info "Todos los prerrequisitos están instalados ✓"
}

# Función para configurar autenticación
function Set-Authentication {
    Write-Step "Configurando autenticación..."
    
    # Verificar autenticación
    $authCheck = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
    if (!$authCheck) {
        Write-Warning "No estás autenticado en Google Cloud"
        Write-Info "Ejecutando: gcloud auth login"
        gcloud auth login
    }
    
    # Configurar autenticación para aplicaciones
    Write-Info "Configurando autenticación para aplicaciones..."
    gcloud auth application-default login
    
    # Instalar plugin de GKE
    Write-Info "Instalando plugin de GKE..."
    gcloud components install gke-gcloud-auth-plugin --quiet
    
    # Habilitar APIs necesarias
    Write-Info "Habilitando APIs necesarias..."
    gcloud services enable container.googleapis.com --quiet
    gcloud services enable artifactregistry.googleapis.com --quiet
    gcloud services enable sqladmin.googleapis.com --quiet
    
    # Obtener proyecto
    $gcpProject = gcloud config get-value project 2>$null
    
    if (!$gcpProject -or $gcpProject -eq "(unset)") {
        Write-Error "No se pudo detectar el proyecto de GCP"
        Write-Warning "Por favor, introduce el ID de tu proyecto:"
        $gcpProject = Read-Host "Project ID"
        
        if (!$gcpProject) {
            Write-Error "Project ID es requerido"
            exit 1
        }
        
        Write-Info "Configurando proyecto: $gcpProject"
        gcloud config set project $gcpProject
    }
    
    Write-Info "Usando proyecto: $gcpProject"
    return $gcpProject
}

# Función para configurar Pulumi
function Set-Pulumi {
    param([string]$GcpProject)
    
    Write-Step "Configurando Pulumi..."
    
    Set-Location pulumi-gcp
    
    # Instalar dependencias
    if (!(Test-Path "node_modules")) {
        Write-Info "Instalando dependencias de Pulumi..."
        npm install
    }
    
    # Configurar stack
    $stackExists = pulumi stack ls 2>$null | Select-String "dev"
    if (!$stackExists) {
        Write-Info "Creando stack dev..."
        pulumi login --local 2>$null
        if ($LASTEXITCODE -ne 0) {
            pulumi login
        }
        pulumi stack init dev
    } else {
        Write-Info "Stack dev ya existe, seleccionándolo..."
        pulumi stack select dev
    }
    
    # Configurar parámetros
    Write-Info "Configurando parámetros de Pulumi..."
    
    $configCheck = pulumi config get gcpProject 2>$null
    if (!$configCheck) {
        pulumi config set gcpProject $GcpProject
    }
    
    $configCheck = pulumi config get gcpRegion 2>$null
    if (!$configCheck) {
        pulumi config set gcpRegion us-central1
    }
    
    $configCheck = pulumi config get gcpZone 2>$null
    if (!$configCheck) {
        pulumi config set gcpZone us-central1-a
    }
    
    $configCheck = pulumi config get minNodes 2>$null
    if (!$configCheck) {
        pulumi config set minNodes 1
    }
    
    $configCheck = pulumi config get maxNodes 2>$null
    if (!$configCheck) {
        pulumi config set maxNodes 3
    }
    
    $configCheck = pulumi config get machineType 2>$null
    if (!$configCheck) {
        pulumi config set machineType e2-small
    }
    
    # Configurar contraseñas
    $configCheck = pulumi config get dbPassword 2>$null
    if (!$configCheck) {
        Write-Warning "Configurando contraseña de base de datos..."
        pulumi config set --secret dbPassword "MiPasswordSeguro123!"
    }
    
    $configCheck = pulumi config get appKey 2>$null
    if (!$configCheck) {
        Write-Info "Generando APP_KEY..."
        $appKey = "base64:$(Get-Random)"
        pulumi config set --secret appKey $appKey
    }
    
    Set-Location ..
}

# Función para desplegar infraestructura
function Deploy-Infrastructure {
    Write-Step "Desplegando infraestructura en Google Cloud..."
    Write-Warning "NOTA: Esto tomará ~15-20 minutos. Usando tu crédito GRATIS de $300."
    
    Set-Location pulumi-gcp
    pulumi up --yes
    
    # Obtener outputs
    $clusterName = pulumi stack output clusterName
    $repoUrl = pulumi stack output repositoryUrl
    $gcpZone = pulumi stack output zone
    $gcpRegion = pulumi stack output region
    $dbHost = pulumi stack output databaseHost
    
    Set-Location ..
    
    return @{
        ClusterName = $clusterName
        RepoUrl = $repoUrl
        GcpZone = $gcpZone
        GcpRegion = $gcpRegion
        DbHost = $dbHost
    }
}

# Función para configurar kubectl
function Set-Kubectl {
    param([string]$ClusterName, [string]$GcpZone, [string]$GcpProject)
    
    Write-Step "Configurando kubectl..."
    
    gcloud container clusters get-credentials $ClusterName --zone $GcpZone --project $GcpProject
    
    Write-Info "kubectl configurado correctamente ✓"
}

# Función para construir y subir imágenes
function Build-AndPushImages {
    param([string]$RepoUrl, [string]$GcpRegion)
    
    Write-Step "Construyendo y subiendo imágenes Docker..."
    
    # Configurar autenticación de Docker
    Write-Info "Configurando autenticación de Docker..."
    gcloud auth configure-docker "${GcpRegion}-docker.pkg.dev"
    
    # Backend
    Write-Info "Construyendo imagen del backend..."
    Set-Location backend
    docker build -t "$RepoUrl/backend:latest" .
    Write-Info "Subiendo imagen del backend..."
    docker push "$RepoUrl/backend:latest"
    Set-Location ..
    
    # Frontend
    Write-Info "Construyendo imagen del frontend..."
    Set-Location frontend
    docker build -t "$RepoUrl/frontend:latest" .
    Write-Info "Subiendo imagen del frontend..."
    docker push "$RepoUrl/frontend:latest"
    Set-Location ..
    
    Write-Info "Imágenes construidas y subidas correctamente ✓"
}

# Función para configurar secretos
function Set-Secrets {
    Write-Step "Configurando secretos..."
    
    # Crear secret para Artifact Registry
    Write-Info "Creando secret para Artifact Registry..."
    $token = gcloud auth print-access-token
    kubectl create secret docker-registry gcp-registry-secret `
        --docker-server=us-central1-docker.pkg.dev `
        --docker-username=_json_key `
        --docker-password=$token `
        --docker-email=no-reply@google.com `
        -n todo `
        --dry-run=client -o yaml | kubectl apply -f -
    
    Write-Info "Secretos configurados correctamente ✓"
}

# Función para desplegar aplicación
function Deploy-Application {
    param([string]$RepoUrl, [string]$DbHost)
    
    Write-Step "Desplegando aplicación en Kubernetes..."
    
    # Esperar a que los nodos estén listos
    Write-Info "Esperando a que los nodos estén listos..."
    kubectl wait --for=condition=Ready nodes --all --timeout=600s
    
    # Crear directorio temporal
    New-Item -ItemType Directory -Force -Path "k8s-temp" | Out-Null
    Copy-Item -Path "k8s-gcp\*" -Destination "k8s-temp\" -Recurse
    
    # Actualizar URLs de imágenes
    Write-Info "Actualizando URLs de imágenes..."
    $backendDeployment = Get-Content "k8s-temp\backend-deployment.yaml"
    $backendDeployment = $backendDeployment -replace "us-central1-docker.pkg.dev/mycloud-jhuamaniv/todo", $RepoUrl
    $backendDeployment | Set-Content "k8s-temp\backend-deployment.yaml"
    
    $frontendDeployment = Get-Content "k8s-temp\frontend-deployment.yaml"
    $frontendDeployment = $frontendDeployment -replace "us-central1-docker.pkg.dev/mycloud-jhuamaniv/todo", $RepoUrl
    $frontendDeployment | Set-Content "k8s-temp\frontend-deployment.yaml"
    
    $mysqlSecret = Get-Content "k8s-temp\mysql-secret.yaml"
    $mysqlSecret = $mysqlSecret -replace "34.69.28.162", $DbHost
    $mysqlSecret | Set-Content "k8s-temp\mysql-secret.yaml"
    
    # Aplicar manifiestos
    Write-Info "Aplicando manifiestos de Kubernetes..."
    kubectl apply -f k8s-temp\
    
    # Esperar a que los pods estén listos
    Write-Info "Esperando a que los pods estén listos..."
    kubectl wait --for=condition=Ready pod -l app=backend -n todo --timeout=300s 2>$null
    kubectl wait --for=condition=Ready pod -l app=frontend -n todo --timeout=300s 2>$null
    
    # Limpiar directorio temporal
    Remove-Item -Path "k8s-temp" -Recurse -Force
    
    Write-Info "Aplicación desplegada correctamente ✓"
}

# Función para verificar despliegue
function Test-Deployment {
    Write-Step "Verificando despliegue..."
    
    # Verificar pods
    Write-Info "Verificando pods..."
    kubectl get pods -n todo
    
    # Verificar servicios
    Write-Info "Verificando servicios..."
    kubectl get services -n todo
    
    # Verificar HPA
    Write-Info "Verificando HPA..."
    kubectl get hpa -n todo
    
    # Verificar Ingress
    Write-Info "Verificando Ingress..."
    kubectl get ingress -n todo
    
    # Obtener IP del Ingress
    $ingressIp = kubectl get ingress todo-ingress -n todo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    
    if ($ingressIp) {
        Write-Info "IP del Ingress: $ingressIp"
        Write-Info "URL de la aplicación: http://$ingressIp"
    } else {
        Write-Warning "El Ingress aún no tiene IP asignada. Espera unos minutos."
    }
    
    Write-Info "Verificación completada ✓"
}

# Función para mostrar información final
function Show-FinalInfo {
    param([string]$ClusterName, [string]$GcpRegion, [string]$GcpZone, [string]$GcpProject, [string]$IngressIp)
    
    Write-Host ""
    Write-Host "==============================================" -ForegroundColor $Cyan
    Write-Info "¡DESPLIEGUE COMPLETADO EXITOSAMENTE! 🎉"
    Write-Host "==============================================" -ForegroundColor $Cyan
    Write-Host ""
    
    Write-Info "Información del cluster:"
    Write-Host "  - Nombre: $ClusterName"
    Write-Host "  - Región: $GcpRegion"
    Write-Host "  - Zona: $GcpZone"
    Write-Host "  - Proyecto: $GcpProject"
    Write-Host ""
    
    if ($IngressIp) {
        Write-Info "🌐 Tu aplicación está disponible en:"
        Write-Host "  http://$IngressIp" -ForegroundColor $Cyan
        Write-Host ""
    }
    
    Write-Info "Comandos útiles:"
    Write-Host "  kubectl get pods -n todo"
    Write-Host "  kubectl get hpa -n todo"
    Write-Host "  kubectl get ingress -n todo"
    Write-Host ""
    
    Write-Info "Para pruebas de carga:"
    Write-Host "  .\scripts\load-test-gcp.ps1"
    Write-Host ""
    
    Write-Warning "IMPORTANTE: Para eliminar todos los recursos:"
    Write-Host "  cd pulumi-gcp && pulumi destroy"
    Write-Host ""
    
    Write-Info "Tu crédito de $300 es suficiente para correr esto por semanas. ¡Disfruta!"
}

# Función principal
function Main {
    Write-Host "==============================================" -ForegroundColor $Cyan
    Write-Host "🚀 DESPLIEGUE COMPLETO - To-Do App en GCP" -ForegroundColor $Cyan
    Write-Host "¡GRATIS con $300 de crédito!" -ForegroundColor $Cyan
    Write-Host "==============================================" -ForegroundColor $Cyan
    Write-Host ""
    
    # Verificar prerrequisitos
    Test-Prerequisites
    Write-Host ""
    
    # Configurar autenticación
    $gcpProject = Set-Authentication
    Write-Host ""
    
    # Configurar Pulumi
    Set-Pulumi $gcpProject
    Write-Host ""
    
    # Desplegar infraestructura
    $infraOutput = Deploy-Infrastructure
    Write-Host ""
    
    # Configurar kubectl
    Set-Kubectl $infraOutput.ClusterName $infraOutput.GcpZone $gcpProject
    Write-Host ""
    
    # Construir y subir imágenes
    Build-AndPushImages $infraOutput.RepoUrl $infraOutput.GcpRegion
    Write-Host ""
    
    # Configurar secretos
    Set-Secrets
    Write-Host ""
    
    # Desplegar aplicación
    Deploy-Application $infraOutput.RepoUrl $infraOutput.DbHost
    Write-Host ""
    
    # Verificar despliegue
    Test-Deployment
    Write-Host ""
    
    # Mostrar información final
    $ingressIp = kubectl get ingress todo-ingress -n todo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    Show-FinalInfo $infraOutput.ClusterName $infraOutput.GcpRegion $infraOutput.GcpZone $gcpProject $ingressIp
}

# Ejecutar función principal
Main
