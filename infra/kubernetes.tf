resource "kubernetes_service_account" "asdda-deployment-sa" {
  metadata {
    name      = "asdda-deployment-sa"
    namespace = "default"
  }
}


resource "kubernetes_role" "asdda-deployment-sa-role" {
  metadata {
    name      = "asdda-deployment-sa-role"
    namespace = kubernetes_service_account.asdda-deployment-sa.metadata.0.namespace
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "create", "delete", "watch"]
  }
}

resource "kubernetes_role_binding" "asdda-deployment-sa-rolebinding" {
  metadata {
    name      = "asdda-deployment-sa-rolebinding"
    namespace = kubernetes_service_account.asdda-deployment-sa.metadata.0.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.asdda-deployment-sa-role.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.asdda-deployment-sa.metadata.0.name
    namespace = kubernetes_service_account.asdda-deployment-sa.metadata.0.namespace
  }
}

data "aws_iam_policy_document" "assda-deployment-sa-role-assume-role-policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "assda-deployment-sa-role" {
  name               = "assda-deployment-sa-role"
  assume_role_policy = data.aws_iam_policy_document.assda-deployment-sa-role-assume-role-policy.json
}


data "aws_iam_policy_document" "assda-deployment-sa-role-policy" {
  statement {
    sid = "1"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${var.company}*",
      "arn:aws:s3:::${var.company}*/*"
    ]
  }
  statement {
    sid = "2"
    actions = [
      "s3:ListAllMyBuckets"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "assda-deployment-sa-role-policy" {
  name   = "ssda-deployment-sa-role-policy"
  role   = aws_iam_role.assda-deployment-sa-role.id
  policy = data.aws_iam_policy_document.assda-deployment-sa-role-policy.json
}


resource "aws_eks_pod_identity_association" "assda-deployment-sa-2-role" {
  cluster_name    = aws_eks_cluster.safe-cluster.name
  namespace       = kubernetes_service_account.asdda-deployment-sa.metadata.0.namespace
  service_account = kubernetes_service_account.asdda-deployment-sa.metadata.0.name
  role_arn        = aws_iam_role.assda-deployment-sa-role.arn
}


resource "kubernetes_secret" "assda-deployment-db-access" {
  metadata {
    name = "assda-deployment-db-access"
  }

  data = {
    username = "admin"
    password = "M33TH4CK{scemo_chi_legge :)}"
  }

  type = "kubernetes.io/basic-auth"
}