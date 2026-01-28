resource "aws_msk_cluster" "this" {
  cluster_name           = var.name
  kafka_version          = "3.5.1"
  number_of_broker_nodes = 2

  broker_node_group_info {
    instance_type   = "kafka.t3.small"
    client_subnets  = var.subnet_ids
    security_groups = var.security_group_ids
  }

  client_authentication {
    sasl {
      iam = true
    }
  }
}
