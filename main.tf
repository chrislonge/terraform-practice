provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "ubuntu-server" {
    ami             = "ami-80861296"
    instance_type   = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.instance.id}"]

    /*
    The <<-EOF and EOF are Terraform’s heredoc syntax, which allows you to create multi‐
    line strings without having to insert newline characters all over the place.
    */
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF

    tags {
        Name = "terraform-example"
    }
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"

    ingress {
        from_port   = "${var.server_port}"
        to_port     = "${var.server_port}"
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

variable "server_port" {
    description = "The port the server will use for HTTP requests."
    default = 8080
}

output "public_ip" {
    value = "${aws_instance.ubuntu-server.public_ip}"
}