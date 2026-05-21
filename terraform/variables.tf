variable "aws_region" {
  description = "Región AWS"
  type        = string
  default     = "us-east-1"
}
 
variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "infra-final"
}
 
variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}