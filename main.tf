###############################################################################
################################ VARIABLES ####################################
###############################################################################

variable "cluster_name" {
  default = "test-cluster"
}

variable "vpc_name" {
  default = "test-vpc"
}

###############################################################################
################################ DATA SOURCES #################################
###############################################################################

# Search for latest Ubuntu server image
data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-*.*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Search for instance type
# Probably t2.small is better, but no time for testing
data "aws_ec2_instance_type_offering" "ubuntu_micro" {
  filter {
    name   = "instance-type"
    values = ["t2.medium"]
  }

  preferred_instance_types = ["t2.medium"]
}

# Availability zones data source to get list of AWS Availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

###############################################################################
################################### VPC #######################################
###############################################################################

# VPC module. Possible to add more config. See the docs
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = var.vpc_name

  cidr            = "10.0.0.0/16"
  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    "k8s.io/cluster-autoscaler/enabled"         = true
    "k8s.io/cluster-autoscaler/jupyterhub"      = "owned"

  }

}

###############################################################################
############################### EKS CLUSTER ###################################
###############################################################################

# Module that creates EKS cluster
# Possible to add more config inputs
# See the docs:
# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.17"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
  ### Here is possible to add Cluster log groups
  ### Uncommented to make JanisK life easier
  # cluster_enabled_log_types = ["audit", "api", "authenticator", "controllerManager", "scheduler"]

  worker_groups = [
    {
      name                 = "worker-group-1"
      instance_type        = data.aws_ec2_instance_type_offering.ubuntu_micro.id
      subnets              = [module.vpc.private_subnets[0]]
      asg_desired_capacity = 1
    },
    {
      name                 = "worker-group-2"
      instance_type        = data.aws_ec2_instance_type_offering.ubuntu_micro.id
      subnets              = [module.vpc.private_subnets[1]]
      asg_desired_capacity = 1
    }
  ]

}

###############################################################################
############################### KUBERNETES CONFIG #############################
###############################################################################

# Data sources used to connect EKS to VPC

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  load_config_file       = false
}


###############################################################################
############################### HELM J-HUB ####################################
###############################################################################

# Helm provider installs in Kubernetes cluster

provider "helm" {

  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    load_config_file       = false
  }
}

# This thing pulls J-hub Helm chart and uses your values.yaml file

resource "helm_release" "jhub" {
  name       = "jupyterhub"
  repository = "https://jupyterhub.github.io/helm-chart/"
  chart      = "jupyterhub"

  values = [
    file("values.yml")
  ]
}

###############################################################################
############################### S3 BUCKETS ####################################
###############################################################################

# Deleted all S3 buckets for now, add your buckets when finished

###############################################################################
################################# OUTPUTS #####################################
###############################################################################

# Possible to add more outputs

output "cluster_id" {
  description = "EKS cluster ID."
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to EKS cluster."
  value       = module.eks.config_map_aws_auth
}

# Aws and kubectl commands to show IP where to acess Jupyterhub
resource "null_resource" "Jhub" {

  provisioner "local-exec" {
    command = "aws eks --region eu-central-1 update-kubeconfig --name test-cluster"
  }

  provisioner "local-exec" {
    command = "kubectl --namespace=default get svc proxy-public"
  }
}
