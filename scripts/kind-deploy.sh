#!/usr/bin/env bash
set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

CLUSTER_NAME="kind-todo"

install_kind() {
  print_status "Instalando kind automáticamente..."
  
  # Detectar sistema operativo
  OS="$(uname -s)"
  ARCH="$(uname -m)"
  
  case "$OS" in
    Linux*)
      if [ "$ARCH" = "x86_64" ]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
      elif [ "$ARCH" = "aarch64" ]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-arm64
      fi
      chmod +x ./kind
      sudo mv ./kind /usr/local/bin/kind
      ;;
    Darwin*)
      if [ "$ARCH" = "x86_64" ]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
      elif [ "$ARCH" = "arm64" ]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-arm64
      fi
      chmod +x ./kind
      sudo mv ./kind /usr/local/bin/kind
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # Windows (Git Bash)
      print_status "Detectado Windows. Descargando kind.exe..."
      curl -Lo kind.exe https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64
      mkdir -p "$HOME/bin"
      mv kind.exe "$HOME/bin/kind.exe"
      export PATH="$HOME/bin:$PATH"
      # Añadir al PATH permanentemente si no está
      if ! grep -q 'export PATH="$HOME/bin:$PATH"' ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
        print_success "PATH actualizado en ~/.bashrc"
      fi
      ;;
    *)
      print_error "Sistema operativo no soportado: $OS"
      print_warning "Instala kind manualmente desde: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
      exit 1
      ;;
  esac
  
  print_success "kind instalado correctamente"
}

install_kubectl() {
  print_status "Instalando kubectl automáticamente..."
  
  OS="$(uname -s)"
  ARCH="$(uname -m)"
  
  case "$OS" in
    Linux*)
      if [ "$ARCH" = "x86_64" ]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      elif [ "$ARCH" = "aarch64" ]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
      fi
      chmod +x ./kubectl
      sudo mv ./kubectl /usr/local/bin/kubectl
      ;;
    Darwin*)
      if [ "$ARCH" = "x86_64" ]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
      elif [ "$ARCH" = "arm64" ]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl"
      fi
      chmod +x ./kubectl
      sudo mv ./kubectl /usr/local/bin/kubectl
      ;;
    MINGW*|MSYS*|CYGWIN*)
      print_status "Detectado Windows. Descargando kubectl.exe..."
      curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/windows/amd64/kubectl.exe"
      mkdir -p "$HOME/bin"
      mv kubectl.exe "$HOME/bin/kubectl.exe"
      export PATH="$HOME/bin:$PATH"
      # Añadir al PATH permanentemente si no está
      if ! grep -q 'export PATH="$HOME/bin:$PATH"' ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
      fi
      ;;
    *)
      print_error "Sistema operativo no soportado: $OS"
      exit 1
      ;;
  esac
  
  print_success "kubectl instalado correctamente"
}

check_prereqs() {
  print_status "Verificando prerrequisitos..."
  
  # Verificar Docker (obligatorio, no auto-instalable fácilmente)
  if ! command -v docker >/dev/null; then
    print_error "Docker no está instalado"
    print_warning "Por favor instala Docker Desktop desde: https://www.docker.com/products/docker-desktop"
    exit 1
  fi
  
  # Verificar/instalar kind
  if ! command -v kind >/dev/null; then
    print_warning "kind no está instalado, instalando automáticamente..."
    install_kind
  fi
  
  # Verificar/instalar kubectl
  if ! command -v kubectl >/dev/null; then
    print_warning "kubectl no está instalado, instalando automáticamente..."
    install_kubectl
  fi
  
  print_success "Prerrequisitos OK"
}

ensure_cluster() {
  print_status "Verificando cluster kind '${CLUSTER_NAME}'..."
  if ! kind get clusters | grep -qx "${CLUSTER_NAME}"; then
    print_status "Creando cluster kind (${CLUSTER_NAME}) con 3 nodos..."
    cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF
  else
    print_success "Cluster kind '${CLUSTER_NAME}' ya existe"
  fi
  kubectl cluster-info --context "kind-${CLUSTER_NAME}" >/dev/null
  kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null
}

cleanup_existing() {
  print_status "Limpiando recursos existentes..."
  kubectl delete ingress --all >/dev/null 2>&1 || true
  kubectl delete all --all >/dev/null 2>&1 || true
  kubectl delete pvc --all >/dev/null 2>&1 || true
  kubectl delete configmap --all >/dev/null 2>&1 || true
  kubectl delete secret --all >/dev/null 2>&1 || true
  print_success "Recursos limpiados"
}

build_images() {
  print_status "Construyendo imágenes Docker locales..."
  ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
  docker build -t todo-complete-backend:local "$ROOT_DIR/backend"
  docker build -t todo-complete-frontend:local "$ROOT_DIR/frontend"
  print_success "Imágenes construidas"
}

load_images_into_kind() {
  print_status "Cargando imágenes en el cluster Kind..."
  kind load docker-image todo-complete-backend:local --name "${CLUSTER_NAME}"
  kind load docker-image todo-complete-frontend:local --name "${CLUSTER_NAME}"
  print_success "Imágenes cargadas en Kind"
}

install_ingress_nginx() {
  print_status "Instalando ingress-nginx para Kind..."
  # Manifiesto recomendado por el proyecto ingress-nginx
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
  print_status "Esperando a que el Ingress Controller esté listo..."
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s
  print_success "ingress-nginx instalado"
}

install_storage_class() {
  print_status "Instalando local-path provisioner para almacenamiento dinámico..."
  # Instalar local-path-provisioner (crea StorageClass 'local-path')
  kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
  # Esperar a que el deployment esté listo
  kubectl -n local-path-storage wait --for=condition=available deploy/local-path-provisioner --timeout=120s || true
  # Crear StorageClass 'standard' si no existe, apuntando al provisioner local-path
  if ! kubectl get storageclass standard >/dev/null 2>&1; then
    print_status "Creando StorageClass 'standard' para Kind..."
    cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF
  else
    print_status "StorageClass 'standard' ya existe"
  fi
  print_success "Almacenamiento dinámico configurado"
}

install_metrics_server() {
  print_status "Instalando metrics-server para habilitar HPA..."
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  print_status "Esperando a que metrics-server esté disponible..."
  # Esperar a que el deployment esté listo (normalmente en kube-system)
  kubectl -n kube-system wait --for=condition=available deploy/metrics-server --timeout=180s || true
  print_success "metrics-server instalado"
}

apply_manifests() {
  print_status "Aplicando manifiestos de Kubernetes..."
  ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
  kubectl apply -f "$ROOT_DIR/k8s/mysql-secret.yaml"
  kubectl apply -f "$ROOT_DIR/k8s/mysql-pvc.yaml"
  kubectl apply -f "$ROOT_DIR/k8s/mysql-service.yaml"
  kubectl apply -f "$ROOT_DIR/k8s/mysql-statefulset.yaml"

  kubectl apply -f "$ROOT_DIR/k8s/backend-configmap.yaml"
  kubectl apply -f "$ROOT_DIR/k8s/backend-service.yaml"
  kubectl apply -f "$ROOT_DIR/k8s/backend-deployment.yaml"

  kubectl apply -f "$ROOT_DIR/k8s/frontend-service.yaml"
  kubectl apply -f "$ROOT_DIR/k8s/frontend-deployment.yaml"

  kubectl apply -f "$ROOT_DIR/k8s/ingress.yaml"
  print_success "Manifiestos aplicados"
}

apply_hpa() {
  print_status "Aplicando Horizontal Pod Autoscaler (HPA)..."
  ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
  if [ -f "$ROOT_DIR/k8s/hpa.yaml" ]; then
    kubectl apply -f "$ROOT_DIR/k8s/hpa.yaml"
    print_success "HPA aplicado"
  else
    print_warning "No se encontró hpa.yaml, omitiendo HPA"
  fi
}

wait_for_ready() {
  print_status "Esperando readiness de MySQL..."
  kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s
  print_status "Esperando readiness de Backend..."
  kubectl wait --for=condition=ready pod -l app=backend --timeout=300s
  print_status "Esperando readiness de Frontend..."
  kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s
  print_success "Todos los pods están listos"
}

seed_database() {
  print_status "Poblando base de datos con datos de ejemplo..."
  kubectl exec deployment/backend -- php artisan db:seed --class=TaskSeeder >/dev/null 2>&1 || true
  print_success "Seeding ejecutado (si procede)"
}

show_access_info() {
  print_success "¡Aplicación desplegada en Kind!"
  echo ""
  echo -e "${BLUE}Opciones de acceso:${NC}"
  echo "1) Port-forward servicios:"
  echo "   kubectl port-forward service/frontend 3000:3000 &"
  echo "   kubectl port-forward service/backend 8000:8000 &"
  echo ""
  echo "2) Usar ingress-nginx en Kind (NodePort en 80):"
  echo "   Abre: http://localhost (mapea al Service del ingress en el nodo)"
  echo ""
  echo -e "${YELLOW}Comandos útiles:${NC}"
  echo "kubectl get pods -A"
  echo "kubectl get svc -A"
  echo "kubectl logs -n ingress-nginx deploy/ingress-nginx-controller"
}

main() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}  To-Do App - Deploy en Kind           ${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""

  check_prereqs
  ensure_cluster
  cleanup_existing
  build_images
  load_images_into_kind
  install_ingress_nginx
  install_storage_class
  install_metrics_server
  apply_manifests
  apply_hpa
  wait_for_ready
  seed_database
  show_access_info

  echo ""
  print_success "Despliegue completado 🎉"
}

main "$@"


