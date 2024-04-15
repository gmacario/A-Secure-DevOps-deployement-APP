data "http" "aws-load-balancer-controller-role-policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.1/docs/install/iam_policy.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_role" "aws-load-balancer-controller-role" {
  name               = "aws-load-balancer-controller-role"
  assume_role_policy = data.aws_iam_policy_document.assda-deployment-sa-role-assume-role-policy.json
}

resource "aws_iam_role_policy" "aws-load-balancer-controller-role-policy" {
  name   = "aws-load-balancer-controller-role-policy"
  role   = aws_iam_role.aws-load-balancer-controller-role.id
  policy = data.http.aws-load-balancer-controller-role-policy.body
}

resource "kubernetes_service_account" "aws-load-balancer-controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
  }
}

resource "aws_eks_pod_identity_association" "aws-load-balancer-controller-2-role" {
  cluster_name    = aws_eks_cluster.safe-cluster.name
  namespace       = kubernetes_service_account.aws-load-balancer-controller.metadata.0.namespace
  service_account = kubernetes_service_account.aws-load-balancer-controller.metadata.0.name
  role_arn        = aws_iam_role.aws-load-balancer-controller-role.arn
}

resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = kubernetes_service_account.aws-load-balancer-controller.metadata.0.namespace

  set {
    name  = "replicaCount"
    value = 1
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.safe-cluster.name
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws-load-balancer-controller.metadata.0.name
  }
}