import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as k8s from "@pulumi/kubernetes";
import { InfrastructureConfig } from "../config";
import { ClusterOutputs } from "./cluster";

export interface ClusterAutoscalerOutputs {
    autoscalerRole: aws.iam.Role;
    autoscalerDeployment: k8s.apps.v1.Deployment;
}

/**
 * Cluster Autoscaler component.
 * Installs AWS Cluster Autoscaler to enable automatic node scaling based on pod resource requests.
 * This allows the cluster to add/remove nodes when pods cannot be scheduled due to resource constraints.
 */
export class ClusterAutoscaler extends pulumi.ComponentResource {
    public readonly autoscalerRole: aws.iam.Role;
    public readonly autoscalerDeployment: k8s.apps.v1.Deployment;

    constructor(
        name: string,
        config: InfrastructureConfig,
        cluster: ClusterOutputs,
        k8sProvider: k8s.Provider,
        opts?: pulumi.ComponentResourceOptions
    ) {
        super("custom:components:ClusterAutoscaler", name, {}, opts);

        // Create IAM role for Cluster Autoscaler
        const accountId = aws.getCallerIdentity({}).then(identity => identity.accountId);
        const oidcIssuer = cluster.cluster.identities.apply(identities => 
            identities[0].oidcs[0].issuer.replace("https://", "")
        );

        this.autoscalerRole = new aws.iam.Role(
            `${config.projectName}-cluster-autoscaler-role`,
            {
                assumeRolePolicy: pulumi.all([accountId, oidcIssuer]).apply(([accId, issuer]) =>
                    JSON.stringify({
                        Version: "2012-10-17",
                        Statement: [
                            {
                                Effect: "Allow",
                                Principal: {
                                    Federated: `arn:aws:iam::${accId}:oidc-provider/${issuer}`,
                                },
                                Action: "sts:AssumeRoleWithWebIdentity",
                                Condition: {
                                    StringEquals: {
                                        [`${issuer}:sub`]: "system:serviceaccount:kube-system:cluster-autoscaler",
                                        [`${issuer}:aud`]: "sts.amazonaws.com",
                                    },
                                },
                            },
                        ],
                    })
                ),
                tags: {
                    Name: `${config.projectName}-cluster-autoscaler-role`,
                },
            },
            { parent: this, dependsOn: [cluster.oidcProvider] }
        );

        // Attach Cluster Autoscaler policy
        const autoscalerPolicy = new aws.iam.RolePolicy(
            `${config.projectName}-cluster-autoscaler-policy`,
            {
                role: this.autoscalerRole.id,
                policy: JSON.stringify({
                    Version: "2012-10-17",
                    Statement: [
                        {
                            Effect: "Allow",
                            Action: [
                                "autoscaling:DescribeAutoScalingGroups",
                                "autoscaling:DescribeAutoScalingInstances",
                                "autoscaling:DescribeLaunchConfigurations",
                                "autoscaling:DescribeScalingActivities",
                                "autoscaling:DescribeTags",
                            ],
                            Resource: "*",
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "autoscaling:SetDesiredCapacity",
                                "autoscaling:TerminateInstanceInAutoScalingGroup",
                                "ec2:DescribeLaunchTemplateVersions",
                            ],
                            Resource: "*",
                        },
                    ],
                }),
            },
            { parent: this, dependsOn: [this.autoscalerRole] }
        );

        // Create ServiceAccount for Cluster Autoscaler
        const autoscalerServiceAccount = new k8s.core.v1.ServiceAccount(
            "cluster-autoscaler",
            {
                metadata: {
                    name: "cluster-autoscaler",
                    namespace: "kube-system",
                    annotations: {
                        "eks.amazonaws.com/role-arn": this.autoscalerRole.arn,
                    },
                    labels: {
                        "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                        "k8s-app": "cluster-autoscaler",
                    },
                },
            },
            {
                provider: k8sProvider,
                parent: this,
                dependsOn: [this.autoscalerRole, autoscalerPolicy],
            }
        );

        // Create ClusterRole
        const autoscalerClusterRole = new k8s.rbac.v1.ClusterRole(
            "cluster-autoscaler",
            {
                metadata: {
                    name: "cluster-autoscaler",
                    labels: {
                        "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                        "k8s-app": "cluster-autoscaler",
                    },
                },
                rules: [
                    {
                        apiGroups: [""],
                        resources: ["events", "endpoints"],
                        verbs: ["create", "patch"],
                    },
                    {
                        apiGroups: [""],
                        resources: ["pods/eviction"],
                        verbs: ["create"],
                    },
                    {
                        apiGroups: [""],
                        resources: ["pods/status"],
                        verbs: ["update"],
                    },
                    {
                        apiGroups: [""],
                        resources: ["endpoints"],
                        resourceNames: ["cluster-autoscaler"],
                        verbs: ["get", "update"],
                    },
                    {
                        apiGroups: [""],
                        resources: ["nodes"],
                        verbs: ["watch", "list", "get", "update"],
                    },
                    {
                        apiGroups: [""],
                        resources: ["namespaces", "pods", "services", "replicationcontrollers", "persistentvolumeclaims", "persistentvolumes"],
                        verbs: ["watch", "list", "get"],
                    },
                    {
                        apiGroups: ["extensions"],
                        resources: ["replicasets", "daemonsets"],
                        verbs: ["watch", "list", "get"],
                    },
                    {
                        apiGroups: ["policy"],
                        resources: ["poddisruptionbudgets"],
                        verbs: ["watch", "list"],
                    },
                    {
                        apiGroups: ["apps"],
                        resources: ["statefulsets", "replicasets", "daemonsets"],
                        verbs: ["watch", "list", "get"],
                    },
                    {
                        apiGroups: ["storage.k8s.io"],
                        resources: ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"],
                        verbs: ["watch", "list", "get"],
                    },
                    {
                        apiGroups: ["batch", "extensions"],
                        resources: ["jobs"],
                        verbs: ["get", "list", "watch", "patch"],
                    },
                    {
                        apiGroups: ["coordination.k8s.io"],
                        resources: ["leases"],
                        verbs: ["create"],
                    },
                    {
                        apiGroups: ["coordination.k8s.io"],
                        resourceNames: ["cluster-autoscaler"],
                        resources: ["leases"],
                        verbs: ["get", "update"],
                    },
                ],
            },
            { provider: k8sProvider, parent: this }
        );

        // Create ClusterRoleBinding
        const autoscalerClusterRoleBinding = new k8s.rbac.v1.ClusterRoleBinding(
            "cluster-autoscaler",
            {
                metadata: {
                    name: "cluster-autoscaler",
                    labels: {
                        "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                        "k8s-app": "cluster-autoscaler",
                    },
                },
                roleRef: {
                    apiGroup: "rbac.authorization.k8s.io",
                    kind: "ClusterRole",
                    name: autoscalerClusterRole.metadata.name,
                },
                subjects: [
                    {
                        kind: "ServiceAccount",
                        name: autoscalerServiceAccount.metadata.name,
                        namespace: autoscalerServiceAccount.metadata.namespace,
                    },
                ],
            },
            { provider: k8sProvider, parent: this, dependsOn: [autoscalerClusterRole, autoscalerServiceAccount] }
        );

        // Get Auto Scaling Group name from Node Group
        const asgName = pulumi.all([cluster.nodeGroup.resources]).apply(resources => {
            // The ASG name is typically derived from the node group name
            return `${config.projectName}-node-group`;
        });

        // Create Deployment for Cluster Autoscaler
        this.autoscalerDeployment = new k8s.apps.v1.Deployment(
            "cluster-autoscaler",
            {
                metadata: {
                    name: "cluster-autoscaler",
                    namespace: "kube-system",
                    labels: {
                        "app": "cluster-autoscaler",
                        "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                        "k8s-app": "cluster-autoscaler",
                    },
                },
                spec: {
                    replicas: 1,
                    selector: {
                        matchLabels: {
                            app: "cluster-autoscaler",
                        },
                    },
                    template: {
                        metadata: {
                            labels: {
                                app: "cluster-autoscaler",
                                "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                                "k8s-app": "cluster-autoscaler",
                            },
                        },
                        spec: {
                            serviceAccountName: autoscalerServiceAccount.metadata.name,
                            containers: [
                                {
                                    image: "registry.k8s.io/autoscaling/cluster-autoscaler:v1.31.0",
                                    name: "cluster-autoscaler",
                                    resources: {
                                        limits: {
                                            cpu: "100m",
                                            memory: "600Mi",
                                        },
                                        requests: {
                                            cpu: "100m",
                                            memory: "600Mi",
                                        },
                                    },
                                    command: pulumi.all([cluster.cluster.name]).apply(([clusterName]) => [
                                        "./cluster-autoscaler",
                                        "--v=4",
                                        "--stderrthreshold=info",
                                        "--cloud-provider=aws",
                                        "--skip-nodes-with-local-storage=false",
                                        "--expander=least-waste",
                                        `--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${clusterName}`,
                                        "--balance-similar-node-groups",
                                        "--skip-nodes-with-system-pods=false",
                                    ]),
                                    env: [
                                        {
                                            name: "AWS_REGION",
                                            value: config.awsRegion,
                                        },
                                        {
                                            name: "AWS_STS_REGIONAL_ENDPOINTS",
                                            value: "regional",
                                        },
                                    ],
                                    volumeMounts: [
                                        {
                                            name: "ssl-certs",
                                            mountPath: "/etc/ssl/certs/ca-certificates.crt",
                                            readOnly: true,
                                        },
                                    ],
                                    imagePullPolicy: "Always",
                                },
                            ],
                            volumes: [
                                {
                                    name: "ssl-certs",
                                    hostPath: {
                                        path: "/etc/ssl/certs/ca-bundle.crt",
                                    },
                                },
                            ],
                        },
                    },
                },
            },
            {
                provider: k8sProvider,
                parent: this,
                dependsOn: [autoscalerClusterRoleBinding, cluster.nodeGroup],
            }
        );

        // Tag the Node Group so Cluster Autoscaler can discover it
        // This is done via the node group tags in the cluster component
        // The tag format is: k8s.io/cluster-autoscaler/enabled = true
        // and k8s.io/cluster-autoscaler/<cluster-name> = owned

        this.registerOutputs({
            autoscalerRole: this.autoscalerRole,
            autoscalerDeployment: this.autoscalerDeployment,
        });
    }
}

