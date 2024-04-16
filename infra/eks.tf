data "aws_iam_policy_document" "safe-cluster-role-assume-role-policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "safe-cluster-role" {
  name               = "${var.company}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.safe-cluster-role-assume-role-policy.json
}


resource "aws_iam_role_policy_attachment" "safe-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.safe-cluster-role.name
}


resource "aws_default_subnet" "default_az" {
  for_each          = var.availability_zones
  availability_zone = "${var.region}${each.key}"
  tags = {
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = aws_eks_cluster.safe-cluster.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = aws_eks_cluster.safe-cluster.name
  addon_name   = "kube-proxy"
}


data "aws_iam_policy_document" "safe-node-role-assume-role-policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "safe-node-role" {
  name               = "${var.company}-node-role"
  assume_role_policy = data.aws_iam_policy_document.safe-node-role-assume-role-policy.json
}

resource "aws_iam_role_policy_attachment" "safe-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.safe-node-role.name
}

resource "aws_iam_role_policy_attachment" "safe-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.safe-node-role.name
}

resource "aws_iam_role_policy_attachment" "safe-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.safe-node-role.name
}

resource "aws_eks_node_group" "safe-node" {
  cluster_name    = aws_eks_cluster.safe-cluster.name
  node_group_name = "${var.company}-node"
  node_role_arn   = aws_iam_role.safe-node-role.arn

  subnet_ids = [
    for availability_zone in var.availability_zones :
    aws_default_subnet.default_az[availability_zone].id
  ]

  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.safe-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.safe-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.safe-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_eks_addon" "core-dns" {
  cluster_name = aws_eks_cluster.safe-cluster.name
  addon_name   = "coredns"

  configuration_values = jsonencode({
    replicaCount = 1
  })

  depends_on = [aws_eks_node_group.safe-node]
}

resource "aws_eks_addon" "eks-pod-identity-agent" {
  cluster_name = aws_eks_cluster.safe-cluster.name
  addon_name   = "eks-pod-identity-agent"

  depends_on = [aws_eks_node_group.safe-node]
}

resource "aws_eks_cluster" "safe-cluster" {
  name     = "${var.company}-cluster"
  role_arn = aws_iam_role.safe-cluster-role.arn

  vpc_config {
    subnet_ids = [
      for availability_zone in var.availability_zones :
      aws_default_subnet.default_az[availability_zone].id
    ]
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.safe-cluster-AmazonEKSClusterPolicy
  ]
}


output "endpoint" {
  value = aws_eks_cluster.safe-cluster.endpoint
}

output "cert" {
  value = aws_eks_cluster.safe-cluster.certificate_authority.0.data
}

