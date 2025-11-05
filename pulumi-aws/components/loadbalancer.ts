import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as k8s from "@pulumi/kubernetes";
import { InfrastructureConfig } from "../config";
import { ClusterOutputs } from "./cluster";

export interface LoadBalancerOutputs {
    controllerRole: aws.iam.Role;
    serviceAccount: k8s.core.v1.ServiceAccount;
}

/**
 * Load Balancer component.
 * Creates IAM role and service account for AWS Load Balancer Controller.
 * Note: The AWS Load Balancer Controller itself should be installed via kubectl or Helm
 * after the cluster is created. This component provides the necessary IAM permissions.
 * 
 * To use ALB instead of Classic Load Balancer:
 * 1. Install AWS Load Balancer Controller: kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
 * 2. Use Ingress resources instead of Service type: LoadBalancer
 */
export class LoadBalancer extends pulumi.ComponentResource {
    public readonly controllerRole: aws.iam.Role;
    public readonly serviceAccount: k8s.core.v1.ServiceAccount;

    constructor(
        name: string,
        config: InfrastructureConfig,
        cluster: ClusterOutputs,
        k8sProvider: k8s.Provider,
        opts?: pulumi.ComponentResourceOptions
    ) {
        super("custom:components:LoadBalancer", name, {}, opts);

        // Create IAM role for AWS Load Balancer Controller
        // This role uses IRSA (IAM Roles for Service Accounts) with OIDC provider
        const accountId = aws.getCallerIdentity({}).then(identity => identity.accountId);
        const oidcIssuer = cluster.cluster.identities.apply(identities => 
            identities[0].oidcs[0].issuer.replace("https://", "")
        );

        this.controllerRole = new aws.iam.Role(
            `${config.projectName}-alb-controller-role`,
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
                                        [`${issuer}:sub`]: "system:serviceaccount:kube-system:aws-load-balancer-controller",
                                        [`${issuer}:aud`]: "sts.amazonaws.com",
                                    },
                                },
                            },
                        ],
                    })
                ),
                tags: {
                    Name: `${config.projectName}-alb-controller-role`,
                },
            },
            { parent: this, dependsOn: [cluster.oidcProvider] }
        );

        // Attach AWS managed policy for Load Balancer Controller
        // This is the recommended AWS managed policy
        const controllerPolicyAttachment = new aws.iam.RolePolicyAttachment(
            `${config.projectName}-alb-controller-policy`,
            {
                role: this.controllerRole.name,
                policyArn: "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess",
            },
            { parent: this, dependsOn: [this.controllerRole] }
        );

        // Attach additional policy with specific permissions needed for Load Balancer Controller
        const controllerPolicy = new aws.iam.RolePolicy(
            `${config.projectName}-alb-controller-additional-policy`,
            {
                role: this.controllerRole.id,
                policy: JSON.stringify({
                    Version: "2012-10-17",
                    Statement: [
                        {
                            Effect: "Allow",
                            Action: [
                                "iam:CreateServiceLinkedRole",
                                "ec2:DescribeAccountAttributes",
                                "ec2:DescribeAddresses",
                                "ec2:DescribeAvailabilityZones",
                                "ec2:DescribeInternetGateways",
                                "ec2:DescribeVpcs",
                                "ec2:DescribeVpcPeeringConnections",
                                "ec2:DescribeSubnets",
                                "ec2:DescribeSecurityGroups",
                                "ec2:DescribeInstances",
                                "ec2:DescribeNetworkInterfaces",
                                "ec2:DescribeTags",
                                "ec2:GetCoipPoolUsage",
                                "ec2:DescribeCoipPools",
                                "elasticloadbalancing:DescribeLoadBalancers",
                                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                                "elasticloadbalancing:DescribeListeners",
                                "elasticloadbalancing:DescribeListenerCertificates",
                                "elasticloadbalancing:DescribeSSLPolicies",
                                "elasticloadbalancing:DescribeRules",
                                "elasticloadbalancing:DescribeTargetGroups",
                                "elasticloadbalancing:DescribeTargetGroupAttributes",
                                "elasticloadbalancing:DescribeTargetHealth",
                                "elasticloadbalancing:DescribeTags",
                            ],
                            Resource: "*",
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "cognito-idp:DescribeUserPoolClient",
                                "acm:ListCertificates",
                                "acm:DescribeCertificate",
                                "iam:ListServerCertificates",
                                "iam:GetServerCertificate",
                                "waf-regional:GetWebACL",
                                "waf-regional:GetWebACLForResource",
                                "waf-regional:AssociateWebACL",
                                "waf-regional:DisassociateWebACL",
                                "wafv2:GetWebACL",
                                "wafv2:GetWebACLForResource",
                                "wafv2:AssociateWebACL",
                                "wafv2:DisassociateWebACL",
                                "shield:GetSubscriptionState",
                                "shield:DescribeProtection",
                                "shield:CreateProtection",
                                "shield:DeleteProtection",
                            ],
                            Resource: "*",
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "ec2:AuthorizeSecurityGroupIngress",
                                "ec2:RevokeSecurityGroupIngress",
                            ],
                            Resource: "*",
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "ec2:CreateSecurityGroup",
                            ],
                            Resource: "*",
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "ec2:CreateTags",
                            ],
                            Resource: "arn:aws:ec2:*:*:security-group/*",
                            Condition: {
                                StringEquals: {
                                    "ec2:CreateAction": "CreateSecurityGroup",
                                },
                                Null: {
                                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false",
                                },
                            },
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "ec2:CreateTags",
                                "ec2:DeleteTags",
                            ],
                            Resource: "arn:aws:ec2:*:*:security-group/*",
                            Condition: {
                                Null: {
                                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false",
                                },
                            },
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "ec2:AuthorizeSecurityGroupIngress",
                                "ec2:RevokeSecurityGroupIngress",
                                "ec2:DeleteSecurityGroup",
                            ],
                            Resource: "*",
                            Condition: {
                                Null: {
                                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false",
                                },
                            },
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "elasticloadbalancing:CreateLoadBalancer",
                                "elasticloadbalancing:CreateTargetGroup",
                            ],
                            Resource: "*",
                            Condition: {
                                Null: {
                                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false",
                                },
                            },
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "elasticloadbalancing:CreateListener",
                                "elasticloadbalancing:DeleteListener",
                                "elasticloadbalancing:CreateRule",
                                "elasticloadbalancing:DeleteRule",
                            ],
                            Resource: "*",
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "elasticloadbalancing:AddTags",
                                "elasticloadbalancing:RemoveTags",
                            ],
                            Resource: [
                                "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                                "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                                "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
                            ],
                            Condition: {
                                Null: {
                                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false",
                                },
                            },
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "elasticloadbalancing:AddTags",
                                "elasticloadbalancing:RemoveTags",
                            ],
                            Resource: [
                                "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
                                "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
                                "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
                                "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*",
                            ],
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                                "elasticloadbalancing:SetIpAddressType",
                                "elasticloadbalancing:SetSecurityGroups",
                                "elasticloadbalancing:SetSubnets",
                                "elasticloadbalancing:DeleteLoadBalancer",
                                "elasticloadbalancing:ModifyTargetGroup",
                                "elasticloadbalancing:ModifyTargetGroupAttributes",
                                "elasticloadbalancing:DeleteTargetGroup",
                            ],
                            Resource: "*",
                            Condition: {
                                Null: {
                                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false",
                                },
                            },
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "elasticloadbalancing:RegisterTargets",
                                "elasticloadbalancing:DeregisterTargets",
                            ],
                            Resource: "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                        },
                        {
                            Effect: "Allow",
                            Action: [
                                "elasticloadbalancing:SetWebAcl",
                                "elasticloadbalancing:ModifyListener",
                                "elasticloadbalancing:AddListenerCertificates",
                                "elasticloadbalancing:RemoveListenerCertificates",
                                "elasticloadbalancing:ModifyRule",
                            ],
                            Resource: "*",
                        },
                    ],
                }),
            },
            { parent: this, dependsOn: [this.controllerRole, controllerPolicyAttachment] }
        );

        // Create ServiceAccount for AWS Load Balancer Controller
        // This ServiceAccount will use IRSA (IAM Roles for Service Accounts) to assume the IAM role
        this.serviceAccount = new k8s.core.v1.ServiceAccount(
            "aws-load-balancer-controller",
            {
                metadata: {
                    name: "aws-load-balancer-controller",
                    namespace: "kube-system",
                    annotations: {
                        "eks.amazonaws.com/role-arn": this.controllerRole.arn,
                    },
                },
            },
            {
                provider: k8sProvider,
                parent: this,
                dependsOn: [this.controllerRole, controllerPolicy],
            }
        );

        this.registerOutputs({
            controllerRole: this.controllerRole,
            serviceAccount: this.serviceAccount,
        });
    }
}

