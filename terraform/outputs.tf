output "alb_dns" {
  value = aws_lb.app_alb.dns_name
}

output "app_server_1_ip" {
  value = aws_instance.app_server_1.public_ip
}

output "app_server_2_ip" {
  value = aws_instance.app_server_2.public_ip
}

output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}