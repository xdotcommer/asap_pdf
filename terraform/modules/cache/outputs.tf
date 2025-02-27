output "redis_endpoint" {
  description = "The endpoint of the Redis cluster"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "redis_port" {
  description = "The port number of the Redis cluster"
  value       = aws_elasticache_cluster.main.cache_nodes[0].port
}

output "redis_security_group_id" {
  description = "The ID of the Redis security group"
  value       = var.security_group_id
}

output "redis_connection_string" {
  description = "Redis connection string (without authentication)"
  value       = "redis://${aws_elasticache_cluster.main.cache_nodes[0].address}:${aws_elasticache_cluster.main.cache_nodes[0].port}"
}
