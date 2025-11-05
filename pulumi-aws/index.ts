import * as pulumi from "@pulumi/pulumi";
import { InfrastructureConfig } from "./config";
import { Networking } from "./components/networking";
import { Registry } from "./components/registry";
import { Cluster } from "./components/cluster";
import { Database } from "./components/database";
import { Kubernetes } from "./components/k8s";
import { LoadBalancer } from "./components/loadbalancer";
import { ClusterAutoscaler } from "./components/cluster-autoscaler";

// Cargar configuración centralizada
const config = new InfrastructureConfig();

// Crear componentes de infraestructura
const networking = new Networking(`${config.projectName}-networking`, config);

const registry = new Registry(`${config.projectName}-registry`, config);

const cluster = new Cluster(
    `${config.projectName}-cluster`,
    config,
    {
        vpc: networking.vpc,
        clusterSecurityGroup: networking.clusterSecurityGroup,
    }
);

const database = new Database(
    `${config.projectName}-database`,
    config,
    {
        vpc: networking.vpc,
        clusterSecurityGroup: networking.clusterSecurityGroup,
    },
    { dependsOn: [cluster] }
);

const k8s = new Kubernetes(
    `${config.projectName}-k8s`,
    config,
    {
        cluster: cluster.cluster,
        nodeGroup: cluster.nodeGroup,
        clusterRole: cluster.clusterRole,
        nodeRole: cluster.nodeRole,
        kubeconfig: cluster.kubeconfig,
        oidcProvider: cluster.oidcProvider,
    },
    {
        dbInstance: database.dbInstance,
        dbSecurityGroup: database.dbSecurityGroup,
        dbSubnetGroup: database.dbSubnetGroup,
    }
);

// Create Load Balancer component for AWS Load Balancer Controller
const loadBalancer = new LoadBalancer(
    `${config.projectName}-loadbalancer`,
    config,
    {
        cluster: cluster.cluster,
        nodeGroup: cluster.nodeGroup,
        clusterRole: cluster.clusterRole,
        nodeRole: cluster.nodeRole,
        kubeconfig: cluster.kubeconfig,
        oidcProvider: cluster.oidcProvider,
    },
    k8s.provider,
    { dependsOn: [k8s] }
);

// Create Cluster Autoscaler component for automatic node scaling
const clusterAutoscaler = new ClusterAutoscaler(
    `${config.projectName}-cluster-autoscaler`,
    config,
    {
        cluster: cluster.cluster,
        nodeGroup: cluster.nodeGroup,
        clusterRole: cluster.clusterRole,
        nodeRole: cluster.nodeRole,
        kubeconfig: cluster.kubeconfig,
        oidcProvider: cluster.oidcProvider,
    },
    k8s.provider,
    { dependsOn: [k8s, loadBalancer] }
);

// Exportar valores importantes
export const clusterName = cluster.cluster.name;
export const clusterEndpoint = cluster.cluster.endpoint;
export const kubeconfig = cluster.kubeconfig;
export const region = config.awsRegion;
export const backendRepoUrl = registry.backendRepo.repositoryUrl;
export const frontendRepoUrl = registry.frontendRepo.repositoryUrl;
export const dbHost = database.dbInstance.endpoint;
export const loadBalancerControllerRoleArn = loadBalancer.controllerRole.arn;

// Instrucciones para el usuario
export const nextSteps = pulumi.interpolate`¡AWS infrastructure created successfully! 🎉`;
