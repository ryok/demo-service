resource "aws_elasticache_parameter_group" "practice_terrafrom_ec_pg" {
  name = "practice-terrafrom-ec-pg"
  family = "redis5.0"

  parameter {
    name  = "cluster-enabled"
    value = "no"
  }
}

resource "aws_elasticache_subnet_group" "practice_terrafrom_ec_sg" {
  name       = "practice-terrafrom-ec-sg"
  subnet_ids = [aws_subnet.practice_terrafrom_private_subnet_1a.id, aws_subnet.practice_terrafrom_private_subnet_1c.id]
}

resource "aws_elasticache_replication_group" "practice_terrafrom_ec_rg" {
  replication_group_id          = "practice-terrafrom-ec-rg"
  replication_group_description = "Cluster Disabled"
  engine         = "redis"
  engine_version = "5.0.4"
  number_cache_clusters = 3
  node_type = "cache.m3.medium"
  snapshot_window          = "09:10-10:10"
  snapshot_retention_limit = 7
  maintenance_window = "mon:10:40-mon:11:40"
  automatic_failover_enabled = true
  port                       = 6379
  apply_immediately    = false
  security_group_ids   = [module.redis_sg.security_group_id]
  parameter_group_name = aws_elasticache_parameter_group.practice_terrafrom_ec_pg.name
  subnet_group_name    = aws_elasticache_subnet_group.practice_terrafrom_ec_sg.name
}

module "redis_sg" {
  source = "./security_group"
  name   = "redis-sg"
  vpc_id = aws_vpc.practice_terrafrom_vpc.id
  port   = 6379
  cidr_blocks = [aws_vpc.practice_terrafrom_vpc.cidr_block]
}