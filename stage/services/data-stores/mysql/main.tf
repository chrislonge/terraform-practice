provider "aws" { 
    region = "us-east-1"
}
resource "aws_db_instance" "mysql_db" { 
    engine              = "mysql" 
    allocated_storage   = 10
    instance_class      = "db.t2.micro"
    name                = "example_database"
    username            = "admin"
    password            = "${var.db_password}"
}