# PowerShell script para desplegar en Kind (Windows nativo)
$ErrorActionPreference = "Stop"

$CLUSTER_NAME = "kind-todo"

function Write-Status { Write-Host "[INFO] $args" -ForegroundColor Blue }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Warning { Write-Host "[WARNING] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }

function Install-Kind {
    Write-Status "Instalando kind automáticamente..."
    $kindUrl = "https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64"
    $kindPath = "$env:USERPROFILE\bin\kind.exe"
    
    # Crear directorio bin si no existe
    $binDir = "$env:USERPROFILE\bin"
    if (!(Test-Path $binDir)) {
        New-Item -ItemType Directory -Path $binDir | Out-Null
    }
    
    # Descargar kind
    Invoke-WebRequest -Uri $kindUrl -OutFile $kindPath
    
    # Añadir al PATH de la sesión actual
    $env:Path = "$binDir;$env:Path"
    
    # Añadir al PATH del usuario permanentemente
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$binDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$binDir;$userPath", "User")
        Write-Success "kind instalado y añadido al PATH"
    }
}

function Install-Kubectl {
    Write-Status "Instalando kubectl automáticamente..."
    
    # Obtener última versión
    $version = (Invoke-WebRequest -Uri "https://dl.k8s.io/release/stable.txt" -UseBasicParsing).Content.Trim()
    $kubectlUrl = "https://dl.k8s.io/release/$version/bin/windows/amd64/kubectl.exe"
    $kubectlPath = "$env:USERPROFILE\bin\kubectl.exe"
    
    # Crear directorio bin si no existe
    $binDir = "$env:USERPROFILE\bin"
    if (!(Test-Path $binDir)) {
        New-Item -ItemType Directory -Path $binDir | Out-Null
    }
    
    # Descargar kubectl
    Invoke-WebRequest -Uri $kubectlUrl -OutFile $kubectlPath
    
    # Añadir al PATH de la sesión actual
    $env:Path = "$binDir;$env:Path"
    
    # Añadir al PATH del usuario permanentemente
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$binDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$binDir;$userPath", "User")
        Write-Success "kubectl instalado y añadido al PATH"
    }
}

function Check-Prerequisites {
    Write-Status "Verificando prerrequisitos..."
    
    # Verificar Docker
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker no está instalado"
        Write-Warning "Instala Docker Desktop desde: https://www.docker.com/products/docker-desktop"
        exit 1
    }
    
    # Verificar/instalar kind
    if (!(Get-Command kind -ErrorAction SilentlyContinue)) {
        Write-Warning "kind no está instalado, instalando automáticamente..."
        Install-Kind
    }
    
    # Verificar/instalar kubectl
    if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Warning "kubectl no está instalado, instalando automáticamente..."
        Install-Kubectl
    }
    
    Write-Success "Prerrequisitos OK"
}

function Ensure-Cluster {
    Write-Status "Verificando cluster kind '$CLUSTER_NAME'..."
    
    $clusters = kind get clusters 2>$null
    if ($clusters -notcontains $CLUSTER_NAME) {
        Write-Status "Creando cluster kind ($CLUSTER_NAME) con 3 nodos..."
        
        $config = @"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
"@
        $config | kind create cluster --name $CLUSTER_NAME --config=-
    } else {
        Write-Success "Cluster kind '$CLUSTER_NAME' ya existe"
    }
    
    kubectl cluster-info --context "kind-$CLUSTER_NAME" | Out-Null
    kubectl config use-context "kind-$CLUSTER_NAME" | Out-Null
}

function Cleanup-Existing {
    Write-Status "Limpiando recursos existentes..."
    
    kubectl delete ingress --all 2>$null | Out-Null
    kubectl delete all --all 2>$null | Out-Null
    kubectl delete pvc --all 2>$null | Out-Null
    kubectl delete configmap --all 2>$null | Out-Null
    kubectl delete secret --all 2>$null | Out-Null
    
    Write-Success "Recursos limpiados"
}

function Build-Images {
    Write-Status "Construyendo imágenes Docker locales..."
    
    $rootDir = Split-Path -Parent $PSScriptRoot
    
    docker build -t todo-complete-backend:local "$rootDir\backend"
    docker build -t todo-complete-frontend:local "$rootDir\frontend"
    
    Write-Success "Imágenes construidas"
}

function Load-Images {
    Write-Status "Cargando imágenes en el cluster Kind..."
    
    kind load docker-image todo-complete-backend:local --name $CLUSTER_NAME
    kind load docker-image todo-complete-frontend:local --name $CLUSTER_NAME
    
    Write-Success "Imágenes cargadas en Kind"
}

function Install-IngressNginx {
    Write-Status "Instalando ingress-nginx para Kind..."
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    Write-Status "Esperando a que el Ingress Controller esté listo..."
    kubectl wait --namespace ingress-nginx `
        --for=condition=ready pod `
        --selector=app.kubernetes.io/component=controller `
        --timeout=180s
    
    Write-Success "ingress-nginx instalado"
}

function Install-StorageClass {
    Write-Status "Instalando local-path provisioner para almacenamiento dinámico..."
    
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
    
    kubectl -n local-path-storage wait --for=condition=available deploy/local-path-provisioner --timeout=120s 2>$null | Out-Null
    
    # Crear StorageClass 'standard' si no existe
    $scExists = kubectl get storageclass standard 2>$null
    if (!$scExists) {
        Write-Status "Creando StorageClass 'standard' para Kind..."
        
        $sc = @"
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
"@
        $sc | kubectl apply -f -
    } else {
        Write-Status "StorageClass 'standard' ya existe"
    }
    
    Write-Success "Almacenamiento dinámico configurado"
}

function Apply-Manifests {
    Write-Status "Aplicando manifiestos de Kubernetes..."
    
    $rootDir = Split-Path -Parent $PSScriptRoot
    $k8sDir = "$rootDir\k8s"
    
    kubectl apply -f "$k8sDir\mysql-secret.yaml"
    kubectl apply -f "$k8sDir\mysql-pvc.yaml"
    kubectl apply -f "$k8sDir\mysql-service.yaml"
    kubectl apply -f "$k8sDir\mysql-statefulset.yaml"
    
    kubectl apply -f "$k8sDir\backend-configmap.yaml"
    kubectl apply -f "$k8sDir\backend-service.yaml"
    kubectl apply -f "$k8sDir\backend-deployment.yaml"
    
    kubectl apply -f "$k8sDir\frontend-service.yaml"
    kubectl apply -f "$k8sDir\frontend-deployment.yaml"
    
    kubectl apply -f "$k8sDir\ingress.yaml"
    
    Write-Success "Manifiestos aplicados"
}

function Wait-ForReady {
    Write-Status "Esperando readiness de MySQL..."
    kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s
    
    Write-Status "Esperando readiness de Backend..."
    kubectl wait --for=condition=ready pod -l app=backend --timeout=300s
    
    Write-Status "Esperando readiness de Frontend..."
    kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s
    
    Write-Success "Todos los pods están listos"
}

function Seed-Database {
    Write-Status "Poblando base de datos con datos de ejemplo..."
    kubectl exec deployment/backend -- php artisan db:seed --class=TaskSeeder 2>$null | Out-Null
    Write-Success "Seeding ejecutado"
}

function Show-AccessInfo {
    Write-Success "¡Aplicación desplegada en Kind!"
    Write-Host ""
    Write-Host "Opciones de acceso:" -ForegroundColor Blue
    Write-Host "1) Port-forward servicios:"
    Write-Host "   kubectl port-forward service/frontend 3000:3000"
    Write-Host "   kubectl port-forward service/backend 8000:8000"
    Write-Host ""
    Write-Host "2) Usar ingress-nginx en Kind:"
    Write-Host "   Abre: http://localhost"
    Write-Host ""
    Write-Host "Comandos útiles:" -ForegroundColor Yellow
    Write-Host "kubectl get pods -A"
    Write-Host "kubectl get svc -A"
}

# Main
Write-Host "========================================" -ForegroundColor Blue
Write-Host "  To-Do App - Deploy en Kind (Windows) " -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

Check-Prerequisites
Ensure-Cluster
Cleanup-Existing
Build-Images
Load-Images
Install-IngressNginx
Install-StorageClass
Apply-Manifests
Wait-ForReady
Seed-Database
Show-AccessInfo

Write-Host ""
Write-Success "Despliegue completado 🎉"

