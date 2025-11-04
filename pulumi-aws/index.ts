import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as k8s from "@pulumi/kubernetes";
import * as awsx from "@pulumi/awsx";

// Configuración
const config = new pulumi.Config();
const projectName = "todo";
const awsRegion = config.get("awsRegion") || "us-east-1"; // Usar us-east-1 para free tier

// Configuración del cluster
const minNodes = config.getNumber("minNodes") || 2; // Mínimo 2 nodos para evitar "Too many pods"
const maxNodes = config.getNumber("maxNodes") || 3; // Máximo 3 nodos
const instanceType = config.get("instanceType") || "t3.small"; // t3.small para free tier (si aplica)

// Crear VPC con subredes públicas y privadas
const vpc = new awsx.ec2.Vpc(`${projectName}-vpc`, {
    cidrBlock: "10.0.0.0/16",
    numberOfAvailabilityZones: 2,
    natGateways: {
        strategy: "Single", // 1 NAT Gateway para ahorrar costos
    },
    subnetSpecs: [
        {
            type: awsx.ec2.SubnetType.Public,
            cidrMask: 24,
        },
        {
            type: awsx.ec2.SubnetType.Private,
            cidrMask: 24,
        },
    ],
});

// Crear Security Group para el cluster EKS
const clusterSg = new aws.ec2.SecurityGroup(`${projectName}-cluster-sg`, {
    description: "Security group for EKS cluster",
    vpcId: vpc.vpcId,
    ingress: [
        {
            description: "Allow HTTPS",
            fromPort: 443,
            toPort: 443,
            protocol: "tcp",
            cidrBlocks: ["0.0.0.0/0"],
        },
    ],
    egress: [
        {
            fromPort: 0,
            toPort: 0,
            protocol: "-1",
            cidrBlocks: ["0.0.0.0/0"],
        },
    ],
    tags: {
        Name: `${projectName}-cluster-sg`,
    },
});

// Crear ECR Repository para las imágenes Docker
const backendRepo = new aws.ecr.Repository(`${projectName}-backend-repo`, {
    name: `${projectName}-backend`,
    imageScanningConfiguration: {
        scanOnPush: true,
    },
    imageTagMutability: "MUTABLE",
    forceDelete: true, // Permite eliminar el repositorio aunque contenga imágenes
});

const frontendRepo = new aws.ecr.Repository(`${projectName}-frontend-repo`, {
    name: `${projectName}-frontend`,
    imageScanningConfiguration: {
        scanOnPush: true,
    },
    imageTagMutability: "MUTABLE",
    forceDelete: true, // Permite eliminar el repositorio aunque contenga imágenes
});

// Crear IAM Role para EKS Cluster
const clusterRole = new aws.iam.Role(`${projectName}-cluster-role`, {
    assumeRolePolicy: JSON.stringify({
        Version: "2012-10-17",
        Statement: [
            {
                Effect: "Allow",
                Principal: {
                    Service: "eks.amazonaws.com",
                },
                Action: "sts:AssumeRole",
            },
        ],
    }),
});

// Attach policies necesarias para el cluster
const clusterPolicyAttachment = new aws.iam.RolePolicyAttachment(`${projectName}-cluster-policy`, {
    role: clusterRole.name,
    policyArn: "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
});

// Crear IAM Role para Node Group
const nodeRole = new aws.iam.Role(`${projectName}-node-role`, {
    assumeRolePolicy: JSON.stringify({
        Version: "2012-10-17",
        Statement: [
            {
                Effect: "Allow",
                Principal: {
                    Service: "ec2.amazonaws.com",
                },
                Action: "sts:AssumeRole",
            },
        ],
    }),
});

// Attach policies necesarias para los nodos
const nodePolicies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
];

const nodePolicyAttachments = nodePolicies.map((policy, index) =>
    new aws.iam.RolePolicyAttachment(`${projectName}-node-policy-${index}`, {
        role: nodeRole.name,
        policyArn: policy,
    })
);

// Crear EKS Cluster
const cluster = new aws.eks.Cluster(`${projectName}-cluster`, {
    roleArn: clusterRole.arn,
    vpcConfig: {
        subnetIds: vpc.privateSubnetIds,
        securityGroupIds: [clusterSg.id],
        endpointPrivateAccess: true,
        endpointPublicAccess: true,
    },
    version: "1.28",
    enabledClusterLogTypes: ["api", "audit", "authenticator"],
}, { dependsOn: [clusterPolicyAttachment] });

// Crear Node Group
const nodeGroup = new aws.eks.NodeGroup(`${projectName}-node-group`, {
    clusterName: cluster.name,
    nodeRoleArn: nodeRole.arn,
    subnetIds: vpc.privateSubnetIds,
    
    scalingConfig: {
        desiredSize: minNodes,
        minSize: minNodes,
        maxSize: maxNodes,
    },
    
    instanceTypes: [instanceType],
    
    labels: {
        app: projectName,
    },
    
    tags: {
        "kubernetes.io/cluster/todo": "owned",
    },
}, { dependsOn: [cluster, ...nodePolicyAttachments] });

// Crear kubeconfig
const clusterKubeconfig = pulumi.all([cluster.name, cluster.endpoint, cluster.certificateAuthority])
    .apply(([name, endpoint, certAuth]) => {
        const context = `aws_${awsRegion}_${name}`;
        return `apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${certAuth.data}
    server: ${endpoint}
  name: ${context}
contexts:
- context:
    cluster: ${context}
    user: ${context}
  name: ${context}
current-context: ${context}
kind: Config
preferences: {}
users:
- name: ${context}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - eks
        - get-token
        - --cluster-name
        - ${name}
        - --region
        - ${awsRegion}
`;
    });

// Proveedor de Kubernetes
const k8sProvider = new k8s.Provider(`${projectName}-k8s-provider`, {
    kubeconfig: clusterKubeconfig,
}, { dependsOn: [nodeGroup] });

// Instalar Metrics Server (necesario para HPA)
const metricsServer = new k8s.yaml.ConfigFile(
    "metrics-server",
    {
        file: "https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.0/components.yaml",
    },
    { provider: k8sProvider }
);

// Crear namespace para la aplicación
const appNamespace = new k8s.core.v1.Namespace(
    `${projectName}-namespace`,
    {
        metadata: {
            name: projectName,
        },
    },
    { provider: k8sProvider }
);

// Crear Security Group para RDS
const dbSecurityGroup = new aws.ec2.SecurityGroup(`${projectName}-db-sg`, {
    description: "Security group for RDS MySQL database",
    vpcId: vpc.vpcId,
    ingress: [
        {
            description: "Allow MySQL from EKS cluster security group",
            fromPort: 3306,
            toPort: 3306,
            protocol: "tcp",
            securityGroups: [clusterSg.id],
        },
        {
            description: "Allow MySQL from VPC",
            fromPort: 3306,
            toPort: 3306,
            protocol: "tcp",
            cidrBlocks: ["10.0.0.0/16"], // Permite desde toda la VPC
        },
    ],
    egress: [
        {
            fromPort: 0,
            toPort: 0,
            protocol: "-1",
            cidrBlocks: ["0.0.0.0/0"],
        },
    ],
    tags: {
        Name: `${projectName}-db-sg`,
    },
}, { dependsOn: [clusterSg] });

// Crear RDS MySQL Database Instance (PostgreSQL no está en free tier)
const dbSubnetGroup = new aws.rds.SubnetGroup(`${projectName}-db-subnet`, {
    subnetIds: vpc.privateSubnetIds,
    tags: {
        Name: `${projectName}-db-subnet`,
    },
});

const dbPassword = config.requireSecret("dbPassword");
const dbInstance = new aws.rds.Instance(`${projectName}-mysql`, {
    engine: "mysql",
    engineVersion: "8.0.37", // Versión disponible en AWS RDS
    instanceClass: "db.t3.micro", // Free tier elegible
    allocatedStorage: 20,
    storageType: "gp2",
    dbName: "mydb",
    username: "admin",
    password: dbPassword,
    
    dbSubnetGroupName: dbSubnetGroup.name,
    vpcSecurityGroupIds: [dbSecurityGroup.id],
    
    backupRetentionPeriod: 7,
    skipFinalSnapshot: true,
    
    tags: {
        Name: `${projectName}-mysql`,
    },
}, { dependsOn: [dbSecurityGroup, dbSubnetGroup] });

// Crear Secret de Kubernetes para MySQL
const mysqlSecret = new k8s.core.v1.Secret(
    "mysql-secret",
    {
        metadata: {
            name: "mysql-secret",
            namespace: appNamespace.metadata.name,
        },
        type: "Opaque",
        stringData: {
            "mysql-user": "admin",
            "mysql-password": dbPassword,
            "mysql-root-password": dbPassword,
            "mysql-host": dbInstance.endpoint,
        },
    },
    { provider: k8sProvider, dependsOn: [appNamespace, dbInstance] }
);

// Crear ConfigMap para el backend
const backendConfigMap = new k8s.core.v1.ConfigMap(
    "backend-config",
    {
        metadata: {
            name: "backend-config",
            namespace: appNamespace.metadata.name,
        },
        data: {
            APP_ENV: "production",
            APP_DEBUG: "false",
            APP_KEY: config.requireSecret("appKey"),
            DB_CONNECTION: "mysql",
            DB_HOST: dbInstance.endpoint,
            DB_PORT: "3306",
            DB_DATABASE: "mydb",
        },
    },
    { provider: k8sProvider, dependsOn: [appNamespace] }
);

// Exportar valores importantes
export const clusterName = cluster.name;
export const clusterEndpoint = cluster.endpoint;
export const kubeconfig = clusterKubeconfig;
export const region = awsRegion;
export const backendRepoUrl = backendRepo.repositoryUrl;
export const frontendRepoUrl = frontendRepo.repositoryUrl;
export const dbHost = dbInstance.endpoint;

// Instrucciones para el usuario
export const nextSteps = pulumi.interpolate`
¡Infraestructura en AWS creada exitosamente! 🎉

IMPORTANTE: Estás usando el tier gratuito de AWS (Free Tier).

Próximos pasos:

1. Configurar kubectl:
   $ aws eks update-kubeconfig --name ${cluster.name} --region ${awsRegion}

2. Autenticar Docker con ECR:
   $ aws ecr get-login-password --region ${awsRegion} | docker login --username AWS --password-stdin ${backendRepoUrl.apply(url => url.split('/')[0])}

3. Construir y subir imágenes:
   $ docker build -t ${backendRepoUrl}:latest ./backend
   $ docker tag ${backendRepoUrl}:latest ${backendRepoUrl}:latest
   $ docker push ${backendRepoUrl}:latest
   
   $ docker build -t ${frontendRepoUrl}:latest ./frontend
   $ docker tag ${frontendRepoUrl}:latest ${frontendRepoUrl}:latest
   $ docker push ${frontendRepoUrl}:latest

4. Actualizar manifiestos de K8s con las nuevas URLs de imágenes y desplegar:
   $ kubectl apply -f k8s-aws/

5. Verificar el autoscaling:
   $ kubectl get hpa -n ${appNamespace.metadata.name}
   $ kubectl top pods -n ${appNamespace.metadata.name}

6. Realizar prueba de carga:
   $ bash scripts/load-test-aws.sh

7. Ver tu costo actual:
   $ aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost

Recuerda: Con AWS Free Tier puedes correr esto durante 12 meses.
T3.small no es siempre gratis, verifica los límites.

Cuando termines, ejecuta 'pulumi destroy' para eliminar recursos.
`;

