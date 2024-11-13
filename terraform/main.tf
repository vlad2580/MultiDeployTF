terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.16.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }
}

provider "postgresql" {
  host     = "localhost"
  port     = 5432
  database = "postgres"
  username = "postgres"
  password = var.postgres_password
  sslmode  = "disable"
}

# List of databases and users
locals {
  databases = ["db1", "db2", "db3"]
  users     = ["user1", "user2", "user3"]
}

# Create databases
resource "postgresql_database" "databases" {
  count = length(local.databases)
  name  = local.databases[count.index]
  owner = "postgres"
}

# Generate passwords for users
resource "random_password" "user_passwords" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  count            = length(local.users)
}

# Create users and assign passwords
resource "postgresql_role" "users" {
  count     = length(local.users)
  name      = local.users[count.index]
  login     = true
  password  = random_password.user_passwords[count.index].result
  superuser = true
}

# Grant full access to each user for their specific database only
resource "postgresql_grant" "user_grants" {
  count       = length(local.users)
  database    = postgresql_database.databases[count.index].name
  object_type = "database"
  privileges  = ["ALL"]
  role        = postgresql_role.users[count.index].name
}

# Create a read-only user with access to all databases
resource "random_password" "readonly_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "postgresql_role" "readonly_user" {
  name     = "readonly_user"
  login    = true
  password = random_password.readonly_password.result
}

# Grant read-only access for all databases
resource "postgresql_grant" "readonly_user_grants" {
  for_each    = toset(postgresql_database.databases[*].name)
  database    = each.key
  object_type = "database"
  privileges  = ["CONNECT"]
  role        = postgresql_role.readonly_user.name

  depends_on = [
    postgresql_database.databases,
    postgresql_role.readonly_user
  ]
}
