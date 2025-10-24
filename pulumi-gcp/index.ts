import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";
import * as k8s from "@pulumi/kubernetes";

// Configuración
const config = new pulumi.Config();
const projectName = "todo";
const gcpProject = config.require("gcpProject");
const gcpRegion = config.get("gcpRegion") || "us-central1";
const gcpZone = config.get("gcpZone") || "us-central1-a";

// Configuración del cluster
const minNodes = config.getNumber("minNodes") || 2;
const maxNodes = config.getNumber("maxNodes") || 10;
const machineType = config.get("machineType") || "e2-medium"; // Similar a t3.medium de AWS

// Habilitar APIs necesarias de GCP (si no están habilitadas)
const computeApi = new gcp.projects.Service("compute-api", {
    service: "compute.googleapis.com",
    project: gcpProject,
});

const containerApi = new gcp.projects.Service("container-api", {
    service: "container.googleapis.com",
    project: gcpProject,
}, { dependsOn: [computeApi] });

const sqlApi = new gcp.projects.Service("sql-api", {
    service: "sqladmin.googleapis.com",
    project: gcpProject,
}, { dependsOn: [computeApi] });

// Crear VPC network
const network = new gcp.compute.Network(`${projectName}-network`, {
    project: gcpProject,
    autoCreateSubnetworks: false,
    description: "VPC network for To-Do App",
}, { dependsOn: [computeApi] });

// Crear subnet
const subnet = new gcp.compute.Subnetwork(`${projectName}-subnet`, {
    project: gcpProject,
    region: gcpRegion,
    network: network.id,
    ipCidrRange: "10.0.0.0/24",
    privateIpGoogleAccess: true,
    secondaryIpRanges: [
        {
            rangeName: "pods",
            ipCidrRange: "10.1.0.0/16",
        },
        {
            rangeName: "services",
            ipCidrRange: "10.2.0.0/16",
        },
    ],
});

// Crear Service Account para el cluster
const clusterSa = new gcp.serviceaccount.Account(`${projectName}-cluster-sa`, {
    project: gcpProject,
    accountId: `${projectName}-cluster`,
    displayName: "Service Account for GKE Cluster",
});

// Asignar roles necesarios al Service Account
const saRoles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
];

const saBindings = saRoles.map((role, index) => 
    new gcp.projects.IAMMember(`${projectName}-sa-role-${index}`, {
        project: gcpProject,
        role: role,
        member: pulumi.interpolate`serviceAccount:${clusterSa.email}`,
    })
);

// Crear GKE Cluster con Autopilot (recomendado para free tier - más eficiente)
// O Standard cluster con autoscaling
const cluster = new gcp.container.Cluster(`${projectName}-cluster`, {
    project: gcpProject,
    location: gcpZone,
    
    // Configuración de red
    network: network.name,
    subnetwork: subnet.name,
    
    ipAllocationPolicy: {
        clusterSecondaryRangeName: "pods",
        servicesSecondaryRangeName: "services",
    },
    
    // Eliminar el node pool por defecto (lo crearemos separado)
    removeDefaultNodePool: true,
    initialNodeCount: 1,
    
    // Habilitar autoscaling del cluster
    clusterAutoscaling: {
        enabled: true,
        autoscalingProfile: "OPTIMIZE_UTILIZATION",
        resourceLimits: [
            {
                resourceType: "cpu",
                minimum: minNodes * 2, // 2 CPUs por nodo e2-medium
                maximum: maxNodes * 2,
            },
            {
                resourceType: "memory",
                minimum: minNodes * 4, // 4GB por nodo e2-medium
                maximum: maxNodes * 4,
            },
        ],
    },
    
    // Habilitar Workload Identity (mejor práctica)
    workloadIdentityConfig: {
        workloadPool: `${gcpProject}.svc.id.goog`,
    },
    
    // Configuración de logging y monitoring
    loggingService: "logging.googleapis.com/kubernetes",
    monitoringService: "monitoring.googleapis.com/kubernetes",
    
    // Addons útiles
    addonsConfig: {
        httpLoadBalancing: { disabled: false },
        horizontalPodAutoscaling: { disabled: false },
    },
    
    // Mantenimiento automático
    maintenancePolicy: {
        dailyMaintenanceWindow: {
            startTime: "03:00",
        },
    },
}, { dependsOn: [containerApi, subnet, ...saBindings] });

// Crear Node Pool con autoscaling
const nodePool = new gcp.container.NodePool(`${projectName}-node-pool`, {
    project: gcpProject,
    location: gcpZone,
    cluster: cluster.name,
    
    initialNodeCount: minNodes,
    
    autoscaling: {
        minNodeCount: minNodes,
        maxNodeCount: maxNodes,
    },
    
    nodeConfig: {
        machineType: machineType,
        serviceAccount: clusterSa.email,
        oauthScopes: [
            "https://www.googleapis.com/auth/cloud-platform",
        ],
        
        // Labels para el node pool
        labels: {
            app: projectName,
        },
        
        // Metadata
        metadata: {
            "disable-legacy-endpoints": "true",
        },
        
        // Workload Identity
        workloadMetadataConfig: {
            mode: "GKE_METADATA",
        },
    },
    
    management: {
        autoRepair: true,
        autoUpgrade: true,
    },
}, { dependsOn: [cluster] });

// Crear kubeconfig
const clusterKubeconfig = pulumi.all([cluster.name, cluster.endpoint, cluster.masterAuth])
    .apply(([name, endpoint, auth]) => {
        const context = `gke_${gcpProject}_${gcpZone}_${name}`;
        return `apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${auth.clusterCaCertificate}
    server: https://${endpoint}
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
      command: gke-gcloud-auth-plugin
      installHint: Install gke-gcloud-auth-plugin for use with kubectl by following
        https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
      providerID: gcp
`;
    });

// Proveedor de Kubernetes
const k8sProvider = new k8s.Provider(`${projectName}-k8s-provider`, {
    kubeconfig: clusterKubeconfig,
}, { dependsOn: [nodePool] });

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

// Crear Cloud SQL (MySQL) - Managed database
const dbInstance = new gcp.sql.DatabaseInstance(`${projectName}-mysql`, {
    project: gcpProject,
    region: gcpRegion,
    databaseVersion: "MYSQL_8_0",
    
    settings: {
        tier: "db-f1-micro", // Free tier eligible
        
        ipConfiguration: {
            ipv4Enabled: true,
            authorizedNetworks: [
                {
                    name: "allow-all", // En producción, restringir esto
                    value: "0.0.0.0/0",
                },
            ],
        },
        
        backupConfiguration: {
            enabled: true,
            startTime: "03:00",
        },
        
        maintenanceWindow: {
            day: 7,
            hour: 3,
        },
    },
    
    deletionProtection: false, // Para facilitar destrucción en demos
}, { dependsOn: [sqlApi] });

// Crear database
const database = new gcp.sql.Database(`${projectName}-db`, {
    project: gcpProject,
    instance: dbInstance.name,
    name: "mydb",
});

// Crear usuario de base de datos
const dbPassword = config.requireSecret("dbPassword");
const dbUser = new gcp.sql.User(`${projectName}-db-user`, {
    project: gcpProject,
    instance: dbInstance.name,
    name: "user",
    password: dbPassword,
});

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
            "mysql-user": "user",
            "mysql-password": dbPassword,
            "mysql-root-password": dbPassword,
            "mysql-host": dbInstance.publicIpAddress,
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
            DB_HOST: dbInstance.publicIpAddress,
            DB_PORT: "3306",
            DB_DATABASE: "mydb",
        },
    },
    { provider: k8sProvider, dependsOn: [appNamespace] }
);

// Crear Artifact Registry repository (como ECR en AWS)
const repository = new gcp.artifactregistry.Repository(`${projectName}-repo`, {
    project: gcpProject,
    location: gcpRegion,
    repositoryId: projectName,
    format: "DOCKER",
    description: "Docker repository for To-Do App",
}, { dependsOn: [computeApi] });

// Exportar valores importantes
export const clusterName = cluster.name;
export const clusterEndpoint = cluster.endpoint;
export const kubeconfig = clusterKubeconfig;
export const projectId = gcpProject;
export const region = gcpRegion;
export const zone = gcpZone;
export const repositoryUrl = pulumi.interpolate`${gcpRegion}-docker.pkg.dev/${gcpProject}/${repository.repositoryId}`;
export const dbHost = dbInstance.publicIpAddress;
export const dbConnectionName = dbInstance.connectionName;

// Instrucciones para el usuario
export const nextSteps = pulumi.interpolate`
¡Infraestructura en Google Cloud creada exitosamente! 🎉

IMPORTANTE: Estás usando los $300 de crédito GRATIS de Google Cloud.

Próximos pasos:

1. Configurar kubectl:
   $ gcloud container clusters get-credentials ${cluster.name} --zone ${gcpZone} --project ${gcpProject}

2. Autenticar Docker con Artifact Registry:
   $ gcloud auth configure-docker ${gcpRegion}-docker.pkg.dev

3. Construir y subir imágenes:
   $ docker build -t ${gcpRegion}-docker.pkg.dev/${gcpProject}/${repository.repositoryId}/backend:latest ./backend
   $ docker push ${gcpRegion}-docker.pkg.dev/${gcpProject}/${repository.repositoryId}/backend:latest
   
   $ docker build -t ${gcpRegion}-docker.pkg.dev/${gcpProject}/${repository.repositoryId}/frontend:latest ./frontend
   $ docker push ${gcpRegion}-docker.pkg.dev/${gcpProject}/${repository.repositoryId}/frontend:latest

4. Actualizar manifiestos de K8s con las nuevas URLs de imágenes y desplegar:
   $ kubectl apply -f k8s-gcp/

5. Verificar el autoscaling:
   $ kubectl get hpa -n ${appNamespace.metadata.name}
   $ kubectl top pods -n ${appNamespace.metadata.name}

6. Realizar prueba de carga:
   $ bash scripts/load-test-gcp.sh

7. Ver tu crédito restante:
   $ gcloud billing accounts list
   $ gcloud billing budgets list

Recuerda: Tienes $300 de crédito GRATIS por 90 días. Esto es más que suficiente para tus demos.

Cuando termines, ejecuta 'pulumi destroy' para eliminar recursos y ahorrar crédito.
`;

