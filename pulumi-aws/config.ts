import * as pulumi from "@pulumi/pulumi";

/**
 * Centralized infrastructure configuration.
 * All values are externalized to make the stack reusable across environments.
 */
export class InfrastructureConfig {
    public readonly projectName: string;
    public readonly awsRegion: string;
    
    // Network configuration
    public readonly vpcCidr: string;
    public readonly numberOfAvailabilityZones: number;
    public readonly natGatewayStrategy: "Single" | "OnePerAz" | "None";
    public readonly subnetCidrMask: number;
    
    // EKS cluster configuration
    public readonly minNodes: number;
    public readonly maxNodes: number;
    public readonly desiredNodes: number;
    public readonly instanceType: string;
    public readonly clusterVersion: string;
    public readonly endpointPrivateAccess: boolean;
    public readonly endpointPublicAccess: boolean;
    
    // Database configuration
    public readonly dbEngine: string;
    public readonly dbEngineVersion: string;
    public readonly dbInstanceClass: string;
    public readonly dbAllocatedStorage: number;
    public readonly dbStorageType: string;
    public readonly dbName: string;
    public readonly dbUsername: string;
    public readonly dbBackupRetentionPeriod: number;
    public readonly dbMultiAz: boolean;
    public readonly dbSkipFinalSnapshot: boolean;
    
    // ECR configuration
    public readonly enableImageScanning: boolean;
    public readonly imageTagMutability: "MUTABLE" | "IMMUTABLE";
    public readonly forceDeleteRepos: boolean;
    public readonly useExistingRepos: boolean;
    
    // Kubernetes configuration
    public readonly k8sNamespace: string;
    public readonly appEnv: string;
    public readonly appDebug: string;
    
    // Required secrets
    public readonly dbPassword: pulumi.Output<string>;
    public readonly appKey: pulumi.Output<string>;

    constructor() {
        const config = new pulumi.Config();
        
        // Basic configuration
        this.projectName = config.get("projectName") || "todo";
        this.awsRegion = config.get("awsRegion") || "us-east-1";
        
        // Network configuration
        this.vpcCidr = config.get("vpcCidr") || "10.0.0.0/16";
        this.numberOfAvailabilityZones = config.getNumber("numberOfAvailabilityZones") || 2;
        const natStrategy = config.get("natGatewayStrategy") || "Single";
        this.natGatewayStrategy = (natStrategy === "Single" || natStrategy === "OnePerAz" || natStrategy === "None") 
            ? natStrategy 
            : "Single";
        this.subnetCidrMask = config.getNumber("subnetCidrMask") || 24;
        
        // EKS cluster configuration
        this.minNodes = config.getNumber("minNodes") || 2;
        this.maxNodes = config.getNumber("maxNodes") || 3;
        this.desiredNodes = config.getNumber("desiredNodes") || this.minNodes;
        this.instanceType = config.get("instanceType") || "t3.small";
        this.clusterVersion = config.get("clusterVersion") || "1.28";
        this.endpointPrivateAccess = config.getBoolean("endpointPrivateAccess") ?? true;
        this.endpointPublicAccess = config.getBoolean("endpointPublicAccess") ?? true;
        
        // Database configuration
        this.dbEngine = config.get("dbEngine") || "mysql";
        this.dbEngineVersion = config.get("dbEngineVersion") || "8.0.40";
        this.dbInstanceClass = config.get("dbInstanceClass") || "db.t3.micro";
        this.dbAllocatedStorage = config.getNumber("dbAllocatedStorage") || 20;
        this.dbStorageType = config.get("dbStorageType") || "gp2";
        this.dbName = config.get("dbName") || "mydb";
        this.dbUsername = config.get("dbUsername") || "admin";
        this.dbBackupRetentionPeriod = config.getNumber("dbBackupRetentionPeriod") || 7;
        this.dbMultiAz = config.getBoolean("dbMultiAz") ?? false; // Default false for free tier
        this.dbSkipFinalSnapshot = config.getBoolean("dbSkipFinalSnapshot") ?? true;
        
        // ECR configuration
        this.enableImageScanning = config.getBoolean("enableImageScanning") ?? true;
        const mutability = config.get("imageTagMutability") || "MUTABLE";
        this.imageTagMutability = (mutability === "MUTABLE" || mutability === "IMMUTABLE") 
            ? mutability 
            : "MUTABLE";
        this.forceDeleteRepos = config.getBoolean("forceDeleteRepos") ?? true;
        this.useExistingRepos = config.getBoolean("useExistingRepos") ?? false;
        
        // Kubernetes configuration
        this.k8sNamespace = config.get("k8sNamespace") || this.projectName;
        this.appEnv = config.get("appEnv") || "production";
        this.appDebug = config.get("appDebug") || "false";
        
        // Required secrets
        this.dbPassword = config.requireSecret("dbPassword");
        this.appKey = config.requireSecret("appKey");
    }
}

