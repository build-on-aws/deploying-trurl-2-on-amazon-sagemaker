import { CfnOutput, RemovalPolicy, Stack, StackProps, Tags } from "aws-cdk-lib";
import { Construct } from "constructs";

import { Repository } from "aws-cdk-lib/aws-codecommit";
import { IpAddresses, Peer, Port } from "aws-cdk-lib/aws-ec2";
import { GatewayVpcEndpointAwsService, SecurityGroup, SubnetType, Vpc } from "aws-cdk-lib/aws-ec2";
import { BlockPublicAccess, Bucket } from "aws-cdk-lib/aws-s3";

import { VPC_IPV4_CIDR } from "./configuration";

export class InfrastructureSharedStack extends Stack {
  public readonly repository: Repository;
  public readonly dataBucket: Bucket;
  public readonly vpc: Vpc;
  public readonly studioSecurityGroup: SecurityGroup;

  constructor (scope: Construct, id: string, props: StackProps) {
    super(scope, id, props);

    // AWS CodeCommit Git repository shared across AWS Cloud9 instances.

    this.repository = new Repository(this, "CodeRepository", {
      repositoryName: "deploying-trurl-2-on-amazon-sagemaker",
      description:
        "Source code for 'Deploying TRURL 2 on Amazon SageMaker' blog post on Community.AWS by Wojciech Gawroński."
    });

    this.repository.applyRemovalPolicy(RemovalPolicy.DESTROY);

    new CfnOutput(this, "CodeRepositoryCloneUrlHTTP", {
      exportName: "CodeRepositoryCloneUrlHTTP",
      value: this.repository.repositoryCloneUrlHttp
    });

    // Shared S3 Bucket for common data.

    this.dataBucket = new Bucket(this, "DataBucket", {
      bucketName: `deploying-trurl-2-on-amazon-sagemaker-common-data-${Stack.of(this).region}`,
      blockPublicAccess: BlockPublicAccess.BLOCK_ALL
    });

    this.dataBucket.applyRemovalPolicy(RemovalPolicy.DESTROY);

    // Another shared element is AWS Networking - where we start with a VPC.

    this.vpc = new Vpc(this, "SharedVPC", {
      ipAddresses: IpAddresses.cidr(VPC_IPV4_CIDR),
      maxAzs: 3,
      natGateways: 3
    });

    // `NATGateway` must wait for `VPCGatewayAttachment`.

    const vpcGateway = this.vpc.node.findChild("VPCGW");

    const nat1 = this.vpc.node.findChild("PublicSubnet1").node.findChild("NATGateway");
    const nat2 = this.vpc.node.findChild("PublicSubnet2").node.findChild("NATGateway");
    const nat3 = this.vpc.node.findChild("PublicSubnet3").node.findChild("NATGateway");

    nat1.node.addDependency(vpcGateway);
    nat2.node.addDependency(vpcGateway);
    nat3.node.addDependency(vpcGateway);

    // VPC Gateway Endpoint for Amazon S3.

    this.vpc.addGatewayEndpoint("VPCGatewayEndpointForS3InSharedVPC", {
      service: GatewayVpcEndpointAwsService.S3,
      subnets: [ { subnetType: SubnetType.PRIVATE_WITH_EGRESS } ]
    });

    // Security group fully opened to all traffic.

    const securityGroupName = "trurl2/sagemaker-studio";

    this.studioSecurityGroup = new SecurityGroup(this, "VPCSecurityGroupForAmazonSageMakerStudio", {
      securityGroupName,
      vpc: this.vpc,
      allowAllOutbound: true
    });

    this.studioSecurityGroup.addIngressRule(
      Peer.anyIpv4(),
      Port.tcp(2049),
      "Incoming EFS traffic."
    );

    this.studioSecurityGroup.addIngressRule(
      this.studioSecurityGroup,
      Port.tcpRange(8192, 65535),
      "Internal studio traffic."
    );

    Tags.of(this.studioSecurityGroup).add("Name", securityGroupName);
  }
}
