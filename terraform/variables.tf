variable "postgres_password" {
  description = "Password for the postgres user (from docker-compose)"
  type        = string
  sensitive   = true
}
