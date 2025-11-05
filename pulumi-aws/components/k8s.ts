import * as pulumi from "@pulumi/pulumi";
import * as k8s from "@pulumi/kubernetes";
import { InfrastructureConfig } from "../config";
import { ClusterOutputs } from "./cluster";
import { DatabaseOutputs } from "./database";

export interface KubernetesOutputs {
    provider: k8s.Provider;
    namespace: k8s.core.v1.Namespace;
    mysqlSecret: k8s.core.v1.Secret;
    backendConfigMap: k8s.core.v1.ConfigMap;
    metricsServer: k8s.yaml.ConfigFile;
}

/**
 * Kubernetes component.
 * Creates the Kubernetes provider, namespace, secrets, configmaps, and metrics server.
 */
export class Kubernetes extends pulumi.ComponentResource {
    public readonly provider: k8s.Provider;
    public readonly namespace: k8s.core.v1.Namespace;
    public readonly mysqlSecret: k8s.core.v1.Secret;
    public readonly backendConfigMap: k8s.core.v1.ConfigMap;
    public readonly metricsServer: k8s.yaml.ConfigFile;

    constructor(
        name: string,
        config: InfrastructureConfig,
        cluster: ClusterOutputs,
        database: DatabaseOutputs,
        opts?: pulumi.ComponentResourceOptions
    ) {
        super("custom:components:Kubernetes", name, {}, opts);

        // Create Kubernetes provider
        this.provider = new k8s.Provider(
            `${config.projectName}-k8s-provider`,
            {
                kubeconfig: cluster.kubeconfig,
            },
            { parent: this, dependsOn: [cluster.nodeGroup] }
        );

        // Install Metrics Server (required for HPA)
        this.metricsServer = new k8s.yaml.ConfigFile(
            "metrics-server",
            {
                file: "https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.0/components.yaml",
            },
            { provider: this.provider, parent: this }
        );

        // Create namespace for the application
        this.namespace = new k8s.core.v1.Namespace(
            `${config.projectName}-namespace`,
            {
                metadata: {
                    name: config.k8sNamespace,
                },
            },
            { provider: this.provider, parent: this }
        );

        // Create Kubernetes Secret for MySQL
        this.mysqlSecret = new k8s.core.v1.Secret(
            "mysql-secret",
            {
                metadata: {
                    name: "mysql-secret",
                    namespace: this.namespace.metadata.name,
                },
                type: "Opaque",
                stringData: {
                    "mysql-user": config.dbUsername,
                    "mysql-password": config.dbPassword,
                    "mysql-root-password": config.dbPassword,
                    "mysql-host": database.dbInstance.endpoint,
                },
            },
            {
                provider: this.provider,
                parent: this,
                dependsOn: [this.namespace, database.dbInstance],
            }
        );

        // Create ConfigMap for the backend
        // Use pulumi.all() to properly handle Outputs
        const backendConfigData = pulumi.all([
            config.appKey,
            database.dbInstance.endpoint,
        ]).apply(([appKey, dbHost]) => ({
            APP_ENV: config.appEnv,
            APP_DEBUG: config.appDebug,
            APP_KEY: appKey,
            DB_CONNECTION: config.dbEngine,
            DB_HOST: dbHost,
            DB_PORT: "3306",
            DB_DATABASE: config.dbName,
        }));

        this.backendConfigMap = new k8s.core.v1.ConfigMap(
            "backend-config",
            {
                metadata: {
                    name: "backend-config",
                    namespace: this.namespace.metadata.name,
                },
                data: backendConfigData,
            },
            {
                provider: this.provider,
                parent: this,
                dependsOn: [this.namespace, database.dbInstance],
            }
        );

        this.registerOutputs({
            provider: this.provider,
            namespace: this.namespace,
            mysqlSecret: this.mysqlSecret,
            backendConfigMap: this.backendConfigMap,
            metricsServer: this.metricsServer,
        });
    }
}

