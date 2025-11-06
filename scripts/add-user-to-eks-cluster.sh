#!/bin/bash
set -euo pipefail

CLUSTER_NAME="todo-cluster-3d82559"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
ROOT_USER_ARN="arn:aws:iam::${ACCOUNT_ID}:root"

echo "Agregando usuario root al cluster ${CLUSTER_NAME}..."

# Verificar si eksctl está instalado
if ! command -v eksctl &> /dev/null; then
    echo "Instalando eksctl..."
    ARCH=$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/osx/')
    curl -sLO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_${ARCH}_amd64.tar.gz"
    tar -xzf eksctl_${ARCH}_amd64.tar.gz -C /tmp && rm eksctl_${ARCH}_amd64.tar.gz
    sudo mv /tmp/eksctl /usr/local/bin/eksctl
    sudo chmod +x /usr/local/bin/eksctl
fi

# Agregar el usuario root al cluster
eksctl create iamidentitymapping \
    --cluster ${CLUSTER_NAME} \
    --region ${REGION} \
    --arn ${ROOT_USER_ARN} \
    --group system:masters \
    --username root

echo "Usuario agregado exitosamente!"
echo "Ahora puedes conectarte al cluster con:"
echo "aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}"
