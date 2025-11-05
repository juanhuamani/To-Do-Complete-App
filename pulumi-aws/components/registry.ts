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

        const backendName = `${config.projectName}-backend`;
        const frontendName = `${config.projectName}-frontend`;

        if (config.useExistingRepos) {
            // Referencia a repos existentes por nombre (id)
            this.backendRepo = aws.ecr.Repository.get(
                `${config.projectName}-backend-repo`,
                backendName,
                undefined,
                { parent: this }
            );
            this.frontendRepo = aws.ecr.Repository.get(
                `${config.projectName}-frontend-repo`,
                frontendName,
                undefined,
                { parent: this }
            );
        } else {
            // Crear repos nuevos
            this.backendRepo = new aws.ecr.Repository(
                `${config.projectName}-backend-repo`,
                {
                    name: backendName,
                    imageScanningConfiguration: {
                        scanOnPush: config.enableImageScanning,
                    },
                    imageTagMutability: config.imageTagMutability,
                    forceDelete: config.forceDeleteRepos,
                },
                { parent: this }
            );

            this.frontendRepo = new aws.ecr.Repository(
                `${config.projectName}-frontend-repo`,
                {
                    name: frontendName,
                    imageScanningConfiguration: {
                        scanOnPush: config.enableImageScanning,
                    },
                    imageTagMutability: config.imageTagMutability,
                    forceDelete: config.forceDeleteRepos,
                },
                { parent: this }
            );
        }

        this.registerOutputs({
            backendRepo: this.backendRepo,
            frontendRepo: this.frontendRepo,
        });
    }
}

