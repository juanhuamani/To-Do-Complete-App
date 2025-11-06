import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import { InfrastructureConfig } from "../config";
import { NetworkingOutputs } from "./networking";

export interface DatabaseOutputs {
    dbInstance: aws.rds.Instance;
    dbSecurityGroup: aws.ec2.SecurityGroup;
    dbSubnetGroup: aws.rds.SubnetGroup;
}

/**
 * Database (RDS) component.
 * Creates the RDS Subnet Group, Security Group, and RDS instance with high availability support.
 */
export class Database extends pulumi.ComponentResource {
    public readonly dbInstance: aws.rds.Instance;
    public readonly dbSecurityGroup: aws.ec2.SecurityGroup;
    public readonly dbSubnetGroup: aws.rds.SubnetGroup;

    constructor(
        name: string,
        config: InfrastructureConfig,
        networking: NetworkingOutputs,
        opts?: pulumi.ComponentResourceOptions
    ) {
        super("custom:components:Database", name, {}, opts);

        // Create Security Group for RDS
        this.dbSecurityGroup = new aws.ec2.SecurityGroup(
            `${config.projectName}-db-sg`,
            {
                description: "Security group for RDS MySQL database",
                vpcId: networking.vpc.vpcId,
                ingress: [
                    {
                        description: "Allow MySQL from EKS cluster security group",
                        fromPort: 3306,
                        toPort: 3306,
                        protocol: "tcp",
                        securityGroups: [networking.clusterSecurityGroup.id],
                    },
                    {
                        description: "Allow MySQL from VPC",
                        fromPort: 3306,
                        toPort: 3306,
                        protocol: "tcp",
                        cidrBlocks: [config.vpcCidr],
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
                    Name: `${config.projectName}-db-sg`,
                },
            },
            { parent: this, dependsOn: [networking.clusterSecurityGroup] }
        );

        // Create RDS Subnet Group
        this.dbSubnetGroup = new aws.rds.SubnetGroup(
            `${config.projectName}-db-subnet`,
            {
                subnetIds: networking.vpc.privateSubnetIds,
                tags: {
                    Name: `${config.projectName}-db-subnet`,
                },
            },
            { parent: this }
        );

        // Create RDS MySQL Database Instance
        this.dbInstance = new aws.rds.Instance(
            `${config.projectName}-mysql`,
            {
                engine: config.dbEngine,
                engineVersion: config.dbEngineVersion,
                instanceClass: config.dbInstanceClass,
                allocatedStorage: config.dbAllocatedStorage,
                storageType: config.dbStorageType,
                dbName: config.dbName,
                username: config.dbUsername,
                password: config.dbPassword,
                dbSubnetGroupName: this.dbSubnetGroup.name,
                vpcSecurityGroupIds: [this.dbSecurityGroup.id],
                backupRetentionPeriod: config.dbBackupRetentionPeriod,
                skipFinalSnapshot: config.dbSkipFinalSnapshot,
                // High availability: Multi-AZ deployment
                // Ensures the database is resilient and not a single point of failure (SPOF)
                multiAz: config.dbMultiAz,
                // Apply changes immediately (set to false to apply during maintenance window)
                applyImmediately: false,
                tags: {
                    Name: `${config.projectName}-mysql`,
                },
            },
            {
                parent: this,
                dependsOn: [this.dbSecurityGroup, this.dbSubnetGroup],
                // Ignore changes to engineVersion if it's a downgrade
                // This prevents errors when the database already has a newer version
                ignoreChanges: ["engineVersion"],
            }
        );

        this.registerOutputs({
            dbInstance: this.dbInstance,
            dbSecurityGroup: this.dbSecurityGroup,
            dbSubnetGroup: this.dbSubnetGroup,
        });
    }
}

