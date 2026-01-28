data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "subnet" {
  for_each = toset(data.aws_subnets.default_vpc_subnets.ids)
  id       = each.value
}

locals {
    supported_subnet_ids = [
    for s in data.aws_subnet.subnet : s.id
    if s.availability_zone != "us-east-1e"
  ]
  msk_subnet_ids = slice(local.supported_subnet_ids, 0, 2)
}

module "msk_cluster" {
  source = "../../modules/msk"

  name               = "dataforge-msk-prod"
  subnet_ids         = local.msk_subnet_ids
  security_group_ids = [aws_security_group.msk.id]
}

resource "aws_security_group" "msk" {
  name        = "dataforge-msk-sg"
  description = "MSK security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 9098
    to_port     = 9098
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


