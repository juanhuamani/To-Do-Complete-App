#!/bin/bash

# Menú interactivo para gestión del cluster To-Do App en GCP
# Permite ver información del cluster, nodos, logs, pods, etc.

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

# Función para mostrar el banner
show_banner() {
    clear
    echo -e "${CYAN}=============================================="
    echo -e "🚀 GESTIÓN DE CLUSTER - To-Do App en GCP"
    echo -e "==============================================${NC}"
    echo ""
}

# Función para verificar conexión a kubectl
check_kubectl_connection() {
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "No se puede conectar al cluster de Kubernetes"
        print_warning "Asegúrate de que kubectl esté configurado correctamente"
        print_info "Ejecuta: gcloud container clusters get-credentials <cluster-name> --zone <zone> --project <project>"
        exit 1
    fi
}

# Función para mostrar información general del cluster
show_cluster_info() {
    print_step "Información General del Cluster"
    echo ""
    
    print_info "Información del cluster:"
    kubectl cluster-info
    echo ""
    
    print_info "Versión del cluster:"
    kubectl version --output=yaml | grep -E "(serverVersion|clientVersion)" -A 2
    echo ""
    
    print_info "Contexto actual:"
    kubectl config current-context
    echo ""
    
    print_info "Namespaces disponibles:"
    kubectl get namespaces
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar información de nodos
show_nodes_info() {
    print_step "Información de Nodos"
    echo ""
    
    print_info "Nodos del cluster:"
    kubectl get nodes -o wide
    echo ""
    
    print_info "Uso de recursos de los nodos:"
    kubectl top nodes 2>/dev/null || print_warning "Metrics server no disponible"
    echo ""
    
    print_info "Detalles de los nodos:"
    kubectl describe nodes
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar pods del namespace todo
show_pods_info() {
    print_step "Pods del Namespace 'todo'"
    echo ""
    
    print_info "Pods en el namespace todo:"
    kubectl get pods -n todo -o wide
    echo ""
    
    print_info "Estado detallado de los pods:"
    kubectl describe pods -n todo
    echo ""
    
    print_info "Uso de recursos de los pods:"
    kubectl top pods -n todo 2>/dev/null || print_warning "Metrics server no disponible"
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar servicios
show_services_info() {
    print_step "Servicios del Namespace 'todo'"
    echo ""
    
    print_info "Servicios:"
    kubectl get services -n todo
    echo ""
    
    print_info "Ingress:"
    kubectl get ingress -n todo
    echo ""
    
    print_info "Detalles de servicios:"
    kubectl describe services -n todo
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar HPA (Horizontal Pod Autoscaler)
show_hpa_info() {
    print_step "Horizontal Pod Autoscaler (HPA)"
    echo ""
    
    print_info "HPA configurado:"
    kubectl get hpa -n todo
    echo ""
    
    print_info "Detalles del HPA:"
    kubectl describe hpa -n todo
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar logs de pods
show_logs() {
    print_step "Logs de Pods"
    echo ""
    
    print_info "Pods disponibles en el namespace todo:"
    kubectl get pods -n todo --no-headers | awk '{print $1}'
    echo ""
    
    read -p "Introduce el nombre del pod para ver logs (o 'all' para todos): " pod_name
    
    if [ "$pod_name" = "all" ]; then
        print_info "Mostrando logs de todos los pods..."
        for pod in $(kubectl get pods -n todo --no-headers | awk '{print $1}'); do
            echo -e "${PURPLE}=== Logs de $pod ===${NC}"
            kubectl logs -n todo $pod --tail=50
            echo ""
        done
    elif [ -n "$pod_name" ]; then
        print_info "Mostrando logs de $pod_name..."
        kubectl logs -n todo $pod_name --tail=100 -f
    else
        print_warning "No se especificó un pod"
    fi
    
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para ejecutar comandos en pods
exec_into_pod() {
    print_step "Ejecutar Comandos en Pods"
    echo ""
    
    print_info "Pods disponibles en el namespace todo:"
    kubectl get pods -n todo --no-headers | awk '{print $1}'
    echo ""
    
    read -p "Introduce el nombre del pod: " pod_name
    
    if [ -n "$pod_name" ]; then
        print_info "Conectando a $pod_name..."
        print_warning "Usa 'exit' para salir del pod"
        kubectl exec -it -n todo $pod_name -- /bin/bash || kubectl exec -it -n todo $pod_name -- /bin/sh
    else
        print_warning "No se especificó un pod"
    fi
    
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar eventos
show_events() {
    print_step "Eventos del Cluster"
    echo ""
    
    print_info "Eventos recientes en el namespace todo:"
    kubectl get events -n todo --sort-by='.lastTimestamp'
    echo ""
    
    print_info "Eventos de todo el cluster:"
    kubectl get events --all-namespaces --sort-by='.lastTimestamp' | head -20
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar configuración de recursos
show_resource_config() {
    print_step "Configuración de Recursos"
    echo ""
    
    print_info "ConfigMaps:"
    kubectl get configmaps -n todo
    echo ""
    
    print_info "Secrets:"
    kubectl get secrets -n todo
    echo ""
    
    print_info "PersistentVolumes:"
    kubectl get pv
    echo ""
    
    print_info "PersistentVolumeClaims:"
    kubectl get pvc -n todo
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para realizar pruebas de conectividad
test_connectivity() {
    print_step "Pruebas de Conectividad"
    echo ""
    
    print_info "Probando conectividad con el backend..."
    backend_pod=$(kubectl get pods -n todo -l app=backend --no-headers | head -1 | awk '{print $1}')
    if [ -n "$backend_pod" ]; then
        print_info "Ejecutando curl al backend desde el pod $backend_pod..."
        kubectl exec -n todo $backend_pod -- curl -s http://localhost:8000/api/health || print_warning "No se pudo conectar al backend"
    else
        print_warning "No se encontró pod del backend"
    fi
    echo ""
    
    print_info "Probando conectividad con la base de datos..."
    if [ -n "$backend_pod" ]; then
        kubectl exec -n todo $backend_pod -- php artisan tinker --execute="DB::connection()->getPdo(); echo 'Conexión a DB exitosa';" || print_warning "No se pudo conectar a la base de datos"
    fi
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar métricas de rendimiento
show_performance_metrics() {
    print_step "Métricas de Rendimiento"
    echo ""
    
    print_info "Uso de CPU y memoria de nodos:"
    kubectl top nodes 2>/dev/null || print_warning "Metrics server no disponible"
    echo ""
    
    print_info "Uso de CPU y memoria de pods:"
    kubectl top pods -n todo 2>/dev/null || print_warning "Metrics server no disponible"
    echo ""
    
    print_info "Recursos solicitados vs límites:"
    kubectl describe nodes | grep -A 5 "Allocated resources"
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar información de la aplicación
show_app_info() {
    print_step "Información de la Aplicación"
    echo ""
    
    print_info "URL de la aplicación:"
    ingress_ip=$(kubectl get ingress todo-ingress -n todo -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$ingress_ip" ]; then
        print_success "Aplicación disponible en: http://$ingress_ip"
    else
        print_warning "El Ingress aún no tiene IP asignada"
    fi
    echo ""
    
    print_info "Estado de la aplicación:"
    kubectl get all -n todo
    echo ""
    
    print_info "Información de la base de datos:"
    kubectl get secret mysql-secret -n todo -o yaml | grep -E "(mysql-host|mysql-database)" || print_warning "No se encontró información de la base de datos"
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar información de Google Cloud
show_gcp_info() {
    print_step "Información de Google Cloud"
    echo ""
    
    print_info "Proyecto actual:"
    gcloud config get-value project
    echo ""
    
    print_info "Cuenta autenticada:"
    gcloud auth list --filter=status:ACTIVE --format="value(account)"
    echo ""
    
    print_info "Región y zona configuradas:"
    gcloud config get-value compute/region 2>/dev/null || echo "No configurada"
    gcloud config get-value compute/zone 2>/dev/null || echo "No configurada"
    echo ""
    
    print_info "Clusters disponibles:"
    gcloud container clusters list
    echo ""
    
    print_info "APIs habilitadas:"
    gcloud services list --enabled --filter="name:(container.googleapis.com OR artifactregistry.googleapis.com OR sqladmin.googleapis.com)"
    echo ""
    
    print_info "Cuota y límites:"
    gcloud compute project-info describe --format="value(quotas[].metric,quotas[].limit)" | grep -E "(CPUS|INSTANCES|DISKS)" | head -10
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar información de Pulumi
show_pulumi_info() {
    print_step "Información de Pulumi"
    echo ""
    
    cd pulumi-gcp
    
    print_info "Stack actual:"
    pulumi stack ls
    echo ""
    
    print_info "Configuración del stack:"
    pulumi config
    echo ""
    
    print_info "Outputs del stack:"
    pulumi stack output 2>/dev/null || print_warning "No se pudieron obtener los outputs"
    echo ""
    
    print_info "Estado de los recursos:"
    pulumi stack --show-urns 2>/dev/null || print_warning "No se pudo obtener el estado"
    echo ""
    
    print_info "Historial de actualizaciones:"
    pulumi history --limit 5 2>/dev/null || print_warning "No se pudo obtener el historial"
    echo ""
    
    cd ..
    
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar información de costos
show_cost_info() {
    print_step "Información de Costos y Créditos"
    echo ""
    
    print_info "Cuentas de facturación:"
    gcloud billing accounts list 2>/dev/null || print_warning "No se pudo acceder a la información de facturación"
    echo ""
    
    print_info "Proyectos con facturación habilitada:"
    gcloud billing projects list 2>/dev/null || print_warning "No se pudo acceder a la información de facturación"
    echo ""
    
    print_info "Presupuestos configurados:"
    gcloud billing budgets list 2>/dev/null || print_warning "No se pudo acceder a los presupuestos"
    echo ""
    
    print_info "Estimación de costos del cluster:"
    print_warning "Los clusters GKE tienen costos mínimos con el tier gratuito"
    print_info "- Nodos e2-small: ~$0.02/hora por nodo"
    print_info "- Cloud SQL db-f1-micro: ~$0.017/hora"
    print_info "- Load Balancer: ~$0.025/hora + tráfico"
    print_info "- Artifact Registry: Gratis hasta 0.5GB"
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para gestionar recursos de Pulumi
manage_pulumi_resources() {
    print_step "Gestión de Recursos Pulumi"
    echo ""
    
    cd pulumi-gcp
    
    print_info "Opciones disponibles:"
    echo "1. Ver estado actual"
    echo "2. Actualizar recursos"
    echo "3. Destruir recursos"
    echo "4. Ver historial"
    echo "5. Volver al menú principal"
    echo ""
    
    read -p "Selecciona una opción (1-5): " pulumi_choice
    
    case $pulumi_choice in
        1)
            print_info "Estado actual de los recursos:"
            pulumi stack --show-urns
            ;;
        2)
            print_warning "¿Estás seguro de que quieres actualizar los recursos? (y/N)"
            read -p "Confirmar: " confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                print_info "Actualizando recursos..."
                pulumi up --yes
            else
                print_info "Actualización cancelada"
            fi
            ;;
        3)
            print_warning "⚠️  PELIGRO: Esto eliminará TODOS los recursos del cluster"
            print_warning "¿Estás seguro de que quieres destruir los recursos? (y/N)"
            read -p "Confirmar: " confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                print_warning "Destruyendo recursos..."
                pulumi destroy --yes
            else
                print_info "Destrucción cancelada"
            fi
            ;;
        4)
            print_info "Historial de actualizaciones:"
            pulumi history --limit 10
            ;;
        5)
            print_info "Volviendo al menú principal..."
            ;;
        *)
            print_error "Opción inválida"
            ;;
    esac
    
    cd ..
    
    read -p "Presiona Enter para continuar..."
}

# Función para gestionar recursos de Google Cloud
manage_gcp_resources() {
    print_step "Gestión de Recursos Google Cloud"
    echo ""
    
    print_info "Opciones disponibles:"
    echo "1. Ver clusters disponibles"
    echo "2. Ver instancias de Cloud SQL"
    echo "3. Ver repositorios de Artifact Registry"
    echo "4. Ver Load Balancers"
    echo "5. Ver cuotas y límites"
    echo "6. Volver al menú principal"
    echo ""
    
    read -p "Selecciona una opción (1-6): " gcp_choice
    
    case $gcp_choice in
        1)
            print_info "Clusters de GKE:"
            gcloud container clusters list
            ;;
        2)
            print_info "Instancias de Cloud SQL:"
            gcloud sql instances list
            ;;
        3)
            print_info "Repositorios de Artifact Registry:"
            gcloud artifacts repositories list
            ;;
        4)
            print_info "Load Balancers:"
            gcloud compute forwarding-rules list
            ;;
        5)
            print_info "Cuotas y límites:"
            gcloud compute project-info describe --format="table(quotas.metric,quotas.limit,quotas.usage)"
            ;;
        6)
            print_info "Volviendo al menú principal..."
            ;;
        *)
            print_error "Opción inválida"
            ;;
    esac
    
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar información completa del cluster
show_complete_info() {
    print_step "Información Completa del Cluster"
    echo ""
    
    print_info "=== INFORMACIÓN GENERAL ==="
    kubectl cluster-info
    echo ""
    
    print_info "=== NODOS ==="
    kubectl get nodes -o wide
    echo ""
    
    print_info "=== PODS EN NAMESPACE 'TODO' ==="
    kubectl get pods -n todo -o wide
    echo ""
    
    print_info "=== SERVICIOS E INGRESS ==="
    kubectl get services -n todo
    kubectl get ingress -n todo
    echo ""
    
    print_info "=== HPA (ESCALADO HORIZONTAL) ==="
    kubectl get hpa -n todo
    echo ""
    
    print_info "=== MÉTRICAS DE RECURSOS ==="
    kubectl top nodes 2>/dev/null || print_warning "Metrics server no disponible"
    kubectl top pods -n todo 2>/dev/null || print_warning "Metrics server no disponible"
    echo ""
    
    print_info "=== EVENTOS RECIENTES ==="
    kubectl get events -n todo --sort-by='.lastTimestamp' | tail -5
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para verificar escalado horizontal
test_horizontal_scaling() {
    print_step "Prueba de Escalado Horizontal"
    echo ""
    
    print_info "Estado actual del HPA:"
    kubectl get hpa -n todo
    echo ""
    
    print_info "Estado actual de los pods (Backend):"
    kubectl get pods -n todo -l app=backend
    echo ""
    
    print_info "Estado actual de los pods (Frontend):"
    kubectl get pods -n todo -l app=frontend
    echo ""
    
    print_info "Detalles del HPA:"
    kubectl describe hpa -n todo
    echo ""
    
    print_warning "¿Quieres realizar una prueba de escalado? (y/N)"
    read -p "Confirmar: " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        print_info "Iniciando prueba de escalado..."
        
        # Asegurar que tenemos el mínimo (3 réplicas)
        print_info "Asegurando mínimo de 3 réplicas para backend..."
        kubectl scale deployment backend -n todo --replicas=3
        
        print_info "Asegurando mínimo de 3 réplicas para frontend..."
        kubectl scale deployment frontend -n todo --replicas=3
        
        print_info "Esperando a que el escalado mínimo se complete..."
        timeout 120 kubectl rollout status deployment/backend -n todo || print_warning "Timeout en backend, continuando..."
        timeout 120 kubectl rollout status deployment/frontend -n todo || print_warning "Timeout en frontend, continuando..."
        
        # Configurar cache de Laravel en todos los pods del backend
        print_info "Configurando cache de Laravel en pods del backend..."
        for pod in $(kubectl get pods -n todo -l app=backend --no-headers | awk '{print $1}'); do
            print_info "Configurando cache en pod $pod..."
            kubectl exec -n todo $pod -- php artisan config:cache >/dev/null 2>&1 || print_warning "No se pudo configurar cache en $pod"
            kubectl exec -n todo $pod -- php artisan route:cache >/dev/null 2>&1 || print_warning "No se pudo configurar cache en $pod"
        done
        
        print_info "Estado después del escalado mínimo:"
        kubectl get pods -n todo -l app=backend
        kubectl get pods -n todo -l app=frontend
        echo ""
        
        # Escalar a 4-5 réplicas para probar
        print_info "Escalando backend a 5 réplicas para prueba..."
        kubectl scale deployment backend -n todo --replicas=5
        
        print_info "Escalando frontend a 4 réplicas para prueba..."
        kubectl scale deployment frontend -n todo --replicas=4
        
        print_info "Esperando a que el escalado de prueba se complete..."
        timeout 180 kubectl rollout status deployment/backend -n todo || print_warning "Timeout en backend, continuando..."
        timeout 180 kubectl rollout status deployment/frontend -n todo || print_warning "Timeout en frontend, continuando..."
        
        # Configurar cache de Laravel en los nuevos pods del backend
        print_info "Configurando cache de Laravel en nuevos pods del backend..."
        for pod in $(kubectl get pods -n todo -l app=backend --no-headers | awk '{print $1}'); do
            print_info "Configurando cache en pod $pod..."
            kubectl exec -n todo $pod -- php artisan config:cache >/dev/null 2>&1 || print_warning "No se pudo configurar cache en $pod"
            kubectl exec -n todo $pod -- php artisan route:cache >/dev/null 2>&1 || print_warning "No se pudo configurar cache en $pod"
        done
        
        print_info "Estado después del escalado de prueba:"
        kubectl get pods -n todo -l app=backend
        kubectl get pods -n todo -l app=frontend
        echo ""
        
        print_info "Estado del HPA después del escalado:"
        kubectl get hpa -n todo
        echo ""
        
        print_warning "¿Quieres volver al mínimo (3 réplicas)? (y/N)"
        read -p "Confirmar: " scale_back
        
        if [ "$scale_back" = "y" ] || [ "$scale_back" = "Y" ]; then
            print_info "Volviendo a 3 réplicas (mínimo)..."
            kubectl scale deployment backend -n todo --replicas=3
            kubectl scale deployment frontend -n todo --replicas=3
            
            print_info "Esperando a que el escalado se complete..."
            timeout 120 kubectl rollout status deployment/backend -n todo || print_warning "Timeout en backend, continuando..."
            timeout 120 kubectl rollout status deployment/frontend -n todo || print_warning "Timeout en frontend, continuando..."
            
            # Configurar cache de Laravel en todos los pods del backend
            print_info "Configurando cache de Laravel en pods del backend..."
            for pod in $(kubectl get pods -n todo -l app=backend --no-headers | awk '{print $1}'); do
                print_info "Configurando cache en pod $pod..."
                kubectl exec -n todo $pod -- php artisan config:cache >/dev/null 2>&1 || print_warning "No se pudo configurar cache en $pod"
                kubectl exec -n todo $pod -- php artisan route:cache >/dev/null 2>&1 || print_warning "No se pudo configurar cache en $pod"
            done
            
            print_info "Estado final:"
            kubectl get pods -n todo -l app=backend
            kubectl get pods -n todo -l app=frontend
            echo ""
            
            print_info "Estado final del HPA:"
            kubectl get hpa -n todo
        else
            print_info "Manteniendo escalado de prueba activo"
        fi
    else
        print_info "Prueba de escalado cancelada"
    fi
    
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar información de Google Cloud y Pulumi
show_infrastructure_info() {
    print_step "Información de Infraestructura"
    echo ""
    
    print_info "=== GOOGLE CLOUD ==="
    print_info "Proyecto: $(gcloud config get-value project)"
    print_info "Cuenta: $(gcloud auth list --filter=status:ACTIVE --format="value(account)")"
    print_info "Región: $(gcloud config get-value compute/region 2>/dev/null || echo "No configurada")"
    print_info "Zona: $(gcloud config get-value compute/zone 2>/dev/null || echo "No configurada")"
    echo ""
    
    print_info "Clusters disponibles:"
    gcloud container clusters list
    echo ""
    
    print_info "=== PULUMI ==="
    if [ -d "pulumi-gcp" ]; then
        cd pulumi-gcp
        print_info "Stack actual:"
        pulumi stack ls 2>/dev/null || print_warning "No se pudo acceder a Pulumi"
        echo ""
        
        print_info "Configuración:"
        pulumi config 2>/dev/null || print_warning "No se pudo acceder a la configuración"
        echo ""
        
        print_info "Outputs:"
        pulumi stack output 2>/dev/null || print_warning "No se pudieron obtener los outputs"
        cd ..
    else
        print_warning "Directorio pulumi-gcp no encontrado"
    fi
    echo ""
    
    print_info "=== COSTOS ESTIMADOS ==="
    print_info "Nodos e2-small: ~$0.02/hora por nodo"
    print_info "Cloud SQL db-f1-micro: ~$0.017/hora"
    print_info "Load Balancer: ~$0.025/hora + tráfico"
    print_info "Artifact Registry: Gratis hasta 0.5GB"
    echo ""
    
    read -p "Presiona Enter para continuar..."
}

# Función para gestión avanzada
show_advanced_management() {
    print_step "Gestión Avanzada"
    echo ""
    
    print_info "Opciones disponibles:"
    echo "1. Ver logs de pods"
    echo "2. Ejecutar comandos en pods"
    echo "3. Reiniciar deployments"
    echo "4. Ver configuración de recursos"
    echo "5. Pruebas de conectividad"
    echo "6. Ejecutar script completo de HPA"
    echo "7. Volver al menú principal"
    echo ""
    
    read -p "Selecciona una opción (1-7): " advanced_choice
    
    case $advanced_choice in
        1)
            print_info "Pods disponibles:"
            kubectl get pods -n todo --no-headers | awk '{print $1}'
            echo ""
            read -p "Introduce el nombre del pod para ver logs: " pod_name
            if [ -n "$pod_name" ]; then
                kubectl logs -n todo $pod_name --tail=50
            fi
            ;;
        2)
            print_info "Pods disponibles:"
            kubectl get pods -n todo --no-headers | awk '{print $1}'
            echo ""
            read -p "Introduce el nombre del pod: " pod_name
            if [ -n "$pod_name" ]; then
                kubectl exec -it -n todo $pod_name -- /bin/bash || kubectl exec -it -n todo $pod_name -- /bin/sh
            fi
            ;;
        3)
            print_warning "¿Reiniciar todos los deployments? (y/N)"
            read -p "Confirmar: " confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                kubectl rollout restart deployment/backend -n todo
                kubectl rollout restart deployment/frontend -n todo
                kubectl rollout status deployment/backend -n todo
                kubectl rollout status deployment/frontend -n todo
            fi
            ;;
        4)
            print_info "ConfigMaps:"
            kubectl get configmaps -n todo
            echo ""
            print_info "Secrets:"
            kubectl get secrets -n todo
            ;;
        5)
            print_info "Probando conectividad..."
            backend_pod=$(kubectl get pods -n todo -l app=backend --no-headers | head -1 | awk '{print $1}')
            if [ -n "$backend_pod" ]; then
                kubectl exec -n todo $backend_pod -- curl -s http://localhost:8000/api/health || print_warning "Backend no responde"
            fi
            ;;
        6)
            print_info "Ejecutando script completo de HPA..."
            bash scripts/test-hpa-scaling-improved.sh
            ;;
        7)
            print_info "Volviendo al menú principal..."
            ;;
        *)
            print_error "Opción inválida"
            ;;
    esac
    
    echo ""
    read -p "Presiona Enter para continuar..."
}

# Función para mostrar el menú principal
show_menu() {
    echo -e "${CYAN}Selecciona una opción:${NC}"
    echo ""
    echo "1.  📊 Información completa del cluster"
    echo "2.  📈 Probar escalado horizontal (3→5 réplicas→3)"
    echo "3.  ☁️  Información de infraestructura (GCP + Pulumi)"
    echo "4.  🔧 Gestión avanzada"
    echo "5.  🔄 Actualizar información"
    echo "6.  ❌ Salir"
    echo ""
}

# Función principal
main() {
    show_banner
    
    # Verificar conexión a kubectl
    check_kubectl_connection
    
    print_success "Conectado al cluster exitosamente"
    echo ""
    
    while true; do
        show_menu
        read -p "Selecciona una opción (1-6): " choice
        
        case $choice in
            1)
                show_complete_info
                ;;
            2)
                test_horizontal_scaling
                ;;
            3)
                show_infrastructure_info
                ;;
            4)
                show_advanced_management
                ;;
            5)
                show_banner
                print_success "Información actualizada"
                ;;
            6)
                print_success "¡Hasta luego! 👋"
                exit 0
                ;;
            *)
                print_error "Opción inválida. Por favor, selecciona una opción del 1 al 6."
                sleep 2
                ;;
        esac
        
        show_banner
    done
}

# Ejecutar función principal
main "$@"
