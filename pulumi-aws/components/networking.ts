import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as awsx from "@pulumi/awsx";
import { InfrastructureConfig } from "../config";

export interface NetworkingOutputs {
    vpc: awsx.ec2.Vpc;
    clusterSecurityGroup: aws.ec2.SecurityGroup;
}

/**
 * Networking component.
 * Creates the VPC, subnets, NAT Gateway, and required Security Groups.
 */
export class Networking extends pulumi.ComponentResource {
    public readonly vpc: awsx.ec2.Vpc;
    public readonly clusterSecurityGroup: aws.ec2.SecurityGroup;

    constructor(
        name: string,
        config: InfrastructureConfig,
        opts?: pulumi.ComponentResourceOptions
    ) {
        super("custom:components:Networking", name, {}, opts);

        // Create VPC with public and private subnets
        this.vpc = new awsx.ec2.Vpc(
            `${config.projectName}-vpc`,
            {
                cidrBlock: config.vpcCidr,
                numberOfAvailabilityZones: config.numberOfAvailabilityZones,
                natGateways: {
                    strategy: config.natGatewayStrategy,
                },
                subnetSpecs: [
                    {
                        type: awsx.ec2.SubnetType.Public,
                        cidrMask: config.subnetCidrMask,
                    },
                    {
                        type: awsx.ec2.SubnetType.Private,
                        cidrMask: config.subnetCidrMask,
                    },
                ],
            },
            { parent: this }
        );

        // Create Security Group for the EKS cluster
        this.clusterSecurityGroup = new aws.ec2.SecurityGroup(
            `${config.projectName}-cluster-sg`,
            {
                description: "Security group for EKS cluster",
                vpcId: this.vpc.vpcId,
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
                    Name: `${config.projectName}-cluster-sg`,
                },
            },
            { parent: this, dependsOn: [this.vpc] }
        );

        this.registerOutputs({
            vpc: this.vpc,
            clusterSecurityGroup: this.clusterSecurityGroup,
        });
    }
}

