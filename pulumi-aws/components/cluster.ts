import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import { InfrastructureConfig } from "../config";
import { NetworkingOutputs } from "./networking";

export interface ClusterOutputs {
    cluster: aws.eks.Cluster;
    nodeGroup: aws.eks.NodeGroup;
    clusterRole: aws.iam.Role;
    nodeRole: aws.iam.Role;
    kubeconfig: pulumi.Output<string>;
    oidcProvider: aws.iam.OpenIdConnectProvider;
}

/**
 * EKS Cluster component.
 * Creates IAM roles, cluster Security Group, EKS cluster, and Node Group.
 */
export class Cluster extends pulumi.ComponentResource {
    public readonly cluster: aws.eks.Cluster;
    public readonly nodeGroup: aws.eks.NodeGroup;
    public readonly clusterRole: aws.iam.Role;
    public readonly nodeRole: aws.iam.Role;
    public readonly kubeconfig: pulumi.Output<string>;
    public readonly oidcProvider: aws.iam.OpenIdConnectProvider;

    constructor(
        name: string,
        config: InfrastructureConfig,
        networking: NetworkingOutputs,
        opts?: pulumi.ComponentResourceOptions
    ) {
        super("custom:components:Cluster", name, {}, opts);

        // Create IAM role for EKS cluster
        this.clusterRole = new aws.iam.Role(
            `${config.projectName}-cluster-role`,
            {
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
            },
            { parent: this }
        );

        // Attach required policies for the cluster
        const clusterPolicyAttachment = new aws.iam.RolePolicyAttachment(
            `${config.projectName}-cluster-policy`,
            {
                role: this.clusterRole.name,
                policyArn: "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
            },
            { parent: this }
        );

        // Create IAM role for Node Group
        this.nodeRole = new aws.iam.Role(
            `${config.projectName}-node-role`,
            {
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
            },
            { parent: this }
        );

        // Attach required policies for the nodes
        const nodePolicies = [
            "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
            "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
            "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
            "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        ];

        const nodePolicyAttachments = nodePolicies.map(
            (policy, index) =>
                new aws.iam.RolePolicyAttachment(
                    `${config.projectName}-node-policy-${index}`,
                    {
                        role: this.nodeRole.name,
                        policyArn: policy,
                    },
                    { parent: this }
                )
        );

        // Create EKS cluster
        this.cluster = new aws.eks.Cluster(
            `${config.projectName}-cluster`,
            {
                roleArn: this.clusterRole.arn,
                vpcConfig: {
                    subnetIds: networking.vpc.privateSubnetIds,
                    securityGroupIds: [networking.clusterSecurityGroup.id],
                    endpointPrivateAccess: config.endpointPrivateAccess,
                    endpointPublicAccess: config.endpointPublicAccess,
                },
                version: config.clusterVersion,
                enabledClusterLogTypes: ["api", "audit", "authenticator"],
            },
            {
                parent: this,
                dependsOn: [clusterPolicyAttachment],
            }
        );

        // Create OIDC provider for IRSA (IAM Roles for Service Accounts)
        // This is required for the Load Balancer Controller to work correctly
        // Get the OIDC issuer URL from the cluster identity
        const oidcIssuerUrl = this.cluster.identities.apply(identities => 
            identities[0].oidcs[0].issuer
        );

        this.oidcProvider = new aws.iam.OpenIdConnectProvider(
            `${config.projectName}-oidc-provider`,
            {
                url: oidcIssuerUrl,
                clientIdLists: ["sts.amazonaws.com"],
                thumbprintLists: [],
            },
            { parent: this, dependsOn: [this.cluster] }
        );

        // Create Node Group
        this.nodeGroup = new aws.eks.NodeGroup(
            `${config.projectName}-node-group`,
            {
                clusterName: this.cluster.name,
                nodeRoleArn: this.nodeRole.arn,
                subnetIds: networking.vpc.privateSubnetIds,
                scalingConfig: {
                    desiredSize: config.desiredNodes,
                    minSize: config.minNodes,
                    maxSize: config.maxNodes,
                },
                instanceTypes: [config.instanceType],
                labels: {
                    app: config.projectName,
                },
                tags: {
                    [`kubernetes.io/cluster/${config.projectName}`]: "owned",
                    // Tags para Cluster Autoscaler
                    "k8s.io/cluster-autoscaler/enabled": "true",
                    [`k8s.io/cluster-autoscaler/${config.projectName}`]: "owned",
                },
            },
            {
                parent: this,
                dependsOn: [this.cluster, ...nodePolicyAttachments],
            }
        );

        // Generate kubeconfig
        this.kubeconfig = pulumi
            .all([
                this.cluster.name,
                this.cluster.endpoint,
                this.cluster.certificateAuthority,
            ])
            .apply(([name, endpoint, certAuth]) => {
                const context = `aws_${config.awsRegion}_${name}`;
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
        - ${config.awsRegion}
`;
            });

        this.registerOutputs({
            cluster: this.cluster,
            nodeGroup: this.nodeGroup,
            clusterRole: this.clusterRole,
            nodeRole: this.nodeRole,
            kubeconfig: this.kubeconfig,
            oidcProvider: this.oidcProvider,
        });
    }
}

