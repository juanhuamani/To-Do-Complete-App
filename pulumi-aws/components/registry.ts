import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import { InfrastructureConfig } from "../config";

export interface RegistryOutputs {
    backendRepo: aws.ecr.Repository;
    frontendRepo: aws.ecr.Repository;
}

/**
 * Registry (ECR) component.
 * Creates ECR repositories for backend and frontend applications.
 */
export class Registry extends pulumi.ComponentResource {
    public readonly backendRepo: aws.ecr.Repository;
    public readonly frontendRepo: aws.ecr.Repository;

    constructor(
        name: string,
        config: InfrastructureConfig,
        opts?: pulumi.ComponentResourceOptions
    ) {
        super("custom:components:Registry", name, {}, opts);

        // Create ECR repository for backend
        this.backendRepo = new aws.ecr.Repository(
            `${config.projectName}-backend-repo`,
            {
                name: `${config.projectName}-backend`,
                imageScanningConfiguration: {
                    scanOnPush: config.enableImageScanning,
                },
                imageTagMutability: config.imageTagMutability,
                forceDelete: config.forceDeleteRepos,
            },
            { parent: this }
        );

        // Create ECR repository for frontend
        this.frontendRepo = new aws.ecr.Repository(
            `${config.projectName}-frontend-repo`,
            {
                name: `${config.projectName}-frontend`,
                imageScanningConfiguration: {
                    scanOnPush: config.enableImageScanning,
                },
                imageTagMutability: config.imageTagMutability,
                forceDelete: config.forceDeleteRepos,
            },
            { parent: this }
        );

        this.registerOutputs({
            backendRepo: this.backendRepo,
            frontendRepo: this.frontendRepo,
        });
    }
}

