####################################
# Karpenter 노드용 IAM Role & Profile
####################################

# EC2(노드) AssumeRole Policy
data "aws_iam_policy_document" "kapen-msa-node-assume-role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Karpenter 노드용 Role
resource "aws_iam_role" "kapen-msa-node" {
  name = "kapen-msa-node"
  assume_role_policy = data.aws_iam_policy_document.kapen-msa-node-assume-role.json
}

# Karpenter 노드용 Instance Profile
resource "aws_iam_instance_profile" "kapen-msa-node" {
  name = "kapen-msa-node"
  role = aws_iam_role.kapen-msa-node.name
}

# Karpenter 노드에 필요한 정책 attach (예시: AmazonEKSWorkerNodePolicy 등)
resource "aws_iam_role_policy_attachment" "kapen-msa-node_worker" {
  role       = aws_iam_role.kapen-msa-node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "kapen-msa-node_ecr" {
  role       = aws_iam_role.kapen-msa-node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "kapen-msa-node_cni" {
  role       = aws_iam_role.kapen-msa-node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "kapen-msa-node_ssm" {
  role       = aws_iam_role.kapen-msa-node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
