import { CfnOutput, Stack, StackProps } from "aws-cdk-lib";
import { Construct } from "constructs";

import { Repository } from "aws-cdk-lib/aws-codecommit";
import { SecurityGroup, Vpc } from "aws-cdk-lib/aws-ec2";
import { ManagedPolicy, Role, ServicePrincipal } from "aws-cdk-lib/aws-iam";
import { CfnDomain, CfnUserProfile } from "aws-cdk-lib/aws-sagemaker";

import * as statement from "cdk-iam-floyd";

interface SageMakerStudioEnvironmentProps extends StackProps {
  vpc: Vpc;
  repository: Repository;
  studioSecurityGroup: SecurityGroup;
  userName: string;
}

export class SageMakerStudioEnvironment extends Stack {
  constructor (scope: Construct, id: string, props: SageMakerStudioEnvironmentProps) {
    super(scope, id, props);

    // Another shared component is Amazon SageMaker Studio Domain and User Profile.

    const sageMakerStudioExecutionRole = new Role(this, "AmazonSageMakerStudioDomainExecutionRole", {
      assumedBy: new ServicePrincipal("sagemaker.amazonaws.com"),
      managedPolicies: [
        ManagedPolicy.fromAwsManagedPolicyName("AmazonSageMakerFullAccess"),
        ManagedPolicy.fromAwsManagedPolicyName("AmazonS3FullAccess"),
        ManagedPolicy.fromAwsManagedPolicyName("AWSLambda_FullAccess"),
        ManagedPolicy.fromAwsManagedPolicyName("IAMReadOnlyAccess")
      ]
    });

    sageMakerStudioExecutionRole.addToPolicy(
      new statement.Codecommit()
        .allow()
        .on(props.repository.repositoryArn)
        .allActions()
    );

    sageMakerStudioExecutionRole.addToPolicy(
      new statement.Codewhisperer()
        .allow()
        .onAllResources()
        .toGenerateRecommendations()
    );

    const sageMakerDomain = new CfnDomain(this, "SharedAmazonSageMakerStudioDomain", {
      domainName: "sagemaker-studio-domain-shared",
      authMode: "IAM",
      appNetworkAccessType: "VpcOnly",
      defaultUserSettings: {
        executionRole: sageMakerStudioExecutionRole.roleArn,
        securityGroups: [ props.studioSecurityGroup.securityGroupId ]
      },
      subnetIds: props.vpc.privateSubnets.map((subnet) => subnet.subnetId),
      vpcId: props.vpc.vpcId
    });

    new CfnOutput(this, "SharedAmazonSageMakerStudioDomainEFS", {
      value: sageMakerDomain.attrHomeEfsFileSystemId
    });

    new CfnOutput(this, "SharedAmazonSageMakerStudioDomainId", {
      value: sageMakerDomain.attrDomainId
    });

    new CfnUserProfile(this, "SharedAmazonSageMakerStudioDomainUserProfile", {
      domainId: sageMakerDomain.attrDomainId,
      userProfileName: props.userName,
    });
  }
}
