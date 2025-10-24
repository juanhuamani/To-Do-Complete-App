# Script para pruebas de carga en Google Cloud GKE
# Demuestra el autoscaling de la aplicación

param(
    [int]$Duration = 60,
    [int]$Concurrency = 15
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

# Función para verificar si hey está instalado
function Test-Hey {
    if (!(Get-Command hey -ErrorAction SilentlyContinue)) {
        Write-Warning "Hey no está instalado. Instalando..."
        
        if (Get-Command go -ErrorAction SilentlyContinue) {
            go install github.com/rakyll/hey@latest
        } else {
            Write-Error "Go no está instalado. Instala Go desde https://golang.org/dl/"
            Write-Info "Alternativamente, puedes instalar hey manualmente:"
            Write-Info "  go install github.com/rakyll/hey@latest"
            exit 1
        }
    }
}

# Función para obtener la URL de la aplicación
function Get-AppUrl {
    $ingressIp = kubectl get ingress todo-ingress -n todo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    
    if (!$ingressIp) {
        Write-Error "No se pudo obtener la IP del Ingress"
        Write-Info "Verifica que el Ingress esté funcionando:"
        Write-Info "  kubectl get ingress -n todo"
        exit 1
    }
    
    return "http://$ingressIp"
}

# Función para mostrar estado inicial
function Show-InitialState {
    Write-Step "Estado inicial de la aplicación"
    
    Write-Info "Pods actuales:"
    kubectl get pods -n todo -o wide
    
    Write-Info "HPA actual:"
    kubectl get hpa -n todo
    
    Write-Info "Recursos de los nodos:"
    $topNodes = kubectl top nodes 2>$null
    if ($topNodes) {
        $topNodes
    } else {
        Write-Warning "Metrics server no disponible"
    }
}

# Función para ejecutar prueba de carga
function Start-LoadTest {
    param([string]$AppUrl, [int]$Duration, [int]$Concurrency)
    
    Write-Step "Ejecutando prueba de carga"
    Write-Info "URL: $AppUrl"
    Write-Info "Duración: ${Duration}s"
    Write-Info "Concurrencia: $Concurrency"
    Write-Info "Endpoint: /api/tasks"
    
    Write-Host ""
    Write-Warning "Iniciando prueba de carga en 5 segundos..."
    Start-Sleep -Seconds 5
    
    # Ejecutar prueba de carga
    $job = Start-Job -ScriptBlock {
        param($url, $duration, $concurrency)
        hey -n 1000 -c $concurrency -t $duration "$url/api/tasks"
    } -ArgumentList $AppUrl, $Duration, $Concurrency
    
    # Monitorear durante la prueba
    Write-Info "Monitoreando durante la prueba..."
    for ($i = 1; $i -le $Duration; $i++) {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
        
        # Mostrar estado cada 10 segundos
        if ($i % 10 -eq 0) {
            Write-Host ""
            Write-Info "Tiempo: ${i}s"
            kubectl get hpa -n todo
            $podCount = (kubectl get pods -n todo --no-headers).Count
            Write-Info "Pods totales: $podCount"
        }
    }
    
    Write-Host ""
    Write-Info "Esperando a que termine la prueba de carga..."
    Wait-Job $job | Out-Null
    Receive-Job $job
    Remove-Job $job
    
    Write-Info "Prueba de carga completada ✓"
}

# Función para mostrar estado final
function Show-FinalState {
    Write-Step "Estado final de la aplicación"
    
    Write-Info "Pods después de la prueba:"
    kubectl get pods -n todo -o wide
    
    Write-Info "HPA después de la prueba:"
    kubectl get hpa -n todo
    
    Write-Info "Recursos de los nodos después de la prueba:"
    $topNodes = kubectl top nodes 2>$null
    if ($topNodes) {
        $topNodes
    } else {
        Write-Warning "Metrics server no disponible"
    }
}

# Función para mostrar métricas de autoscaling
function Show-ScalingMetrics {
    Write-Step "Métricas de autoscaling"
    
    Write-Info "Historial de escalado del backend:"
    $backendEvents = kubectl describe hpa backend-hpa -n todo | Select-String -Pattern "Events:" -Context 0,10
    if ($backendEvents) {
        $backendEvents
    }
    
    Write-Info "Historial de escalado del frontend:"
    $frontendEvents = kubectl describe hpa frontend-hpa -n todo | Select-String -Pattern "Events:" -Context 0,10
    if ($frontendEvents) {
        $frontendEvents
    }
}

# Función para limpiar (opcional)
function Start-Cleanup {
    Write-Step "Limpieza (opcional)"
    
    Write-Warning "¿Quieres esperar a que los pods se reduzcan automáticamente?"
    Write-Info "Esto puede tomar varios minutos debido a la ventana de estabilización del HPA."
    
    $response = Read-Host "¿Esperar a que se reduzcan los pods? (y/N)"
    
    if ($response -match "^[Yy]$") {
        Write-Info "Esperando a que los pods se reduzcan..."
        Write-Info "Esto puede tomar 5-10 minutos..."
        
        while ($true) {
            $currentPods = (kubectl get pods -n todo --no-headers).Count
            $targetPods = kubectl get hpa -n todo -o jsonpath='{.items[0].status.desiredReplicas}'
            
            if ($currentPods -eq $targetPods) {
                Write-Info "Los pods se han reducido al número objetivo ✓"
                break
            }
            
            Write-Info "Pods actuales: $currentPods, Objetivo: $targetPods"
            Start-Sleep -Seconds 30
        }
    }
}

# Función para mostrar resumen
function Show-Summary {
    Write-Step "Resumen de la demostración"
    
    Write-Host ""
    Write-Info "✅ Lo que has demostrado:"
    Write-Host "  - Autoscaling horizontal de pods (HPA)"
    Write-Host "  - Escalado automático basado en CPU y memoria"
    Write-Host "  - Distribución de carga entre múltiples pods"
    Write-Host "  - Recuperación automática después de la carga"
    Write-Host ""
    
    Write-Info "📊 Métricas observadas:"
    Write-Host "  - Número de pods antes y después de la carga"
    Write-Host "  - Utilización de CPU y memoria"
    Write-Host "  - Tiempo de respuesta de la aplicación"
    Write-Host "  - Comportamiento del HPA"
    Write-Host ""
    
    Write-Info "🎯 Beneficios del autoscaling:"
    Write-Host "  - Escalado automático según la demanda"
    Write-Host "  - Optimización de recursos y costos"
    Write-Host "  - Alta disponibilidad y resistencia"
    Write-Host "  - Gestión automática de la carga"
    Write-Host ""
}

# Función principal
function Main {
    Write-Host "==============================================" -ForegroundColor $Cyan
    Write-Host "🧪 PRUEBAS DE CARGA - Autoscaling Demo" -ForegroundColor $Cyan
    Write-Host "==============================================" -ForegroundColor $Cyan
    Write-Host ""
    
    # Verificar prerrequisitos
    Test-Hey
    
    # Obtener URL de la aplicación
    $appUrl = Get-AppUrl
    Write-Info "URL de la aplicación: $appUrl"
    
    # Verificar que la aplicación esté funcionando
    Write-Info "Verificando que la aplicación esté funcionando..."
    try {
        $response = Invoke-WebRequest -Uri "$appUrl/api/hello" -TimeoutSec 10
        if ($response.StatusCode -ne 200) {
            throw "Status code: $($response.StatusCode)"
        }
    } catch {
        Write-Error "La aplicación no está respondiendo"
        Write-Info "Verifica que esté desplegada correctamente:"
        Write-Info "  kubectl get pods -n todo"
        exit 1
    }
    
    Write-Info "Aplicación funcionando correctamente ✓"
    Write-Host ""
    
    # Mostrar estado inicial
    Show-InitialState
    Write-Host ""
    
    # Ejecutar prueba de carga
    Start-LoadTest $appUrl $Duration $Concurrency
    Write-Host ""
    
    # Mostrar estado final
    Show-FinalState
    Write-Host ""
    
    # Mostrar métricas de autoscaling
    Show-ScalingMetrics
    Write-Host ""
    
    # Limpiar (opcional)
    Start-Cleanup
    Write-Host ""
    
    # Mostrar resumen
    Show-Summary
}

# Ejecutar función principal
Main
