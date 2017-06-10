provider "aws" {
    region = "us-east-1"
}

resource "aws_launch_configuration" "launch-config" {
    image_id        = "ami-80861296"
    instance_type   = "t2.micro"
    security_groups = ["${aws_security_group.web-sg.id}"]

    /*
    The <<-EOF and EOF are Terraform’s heredoc syntax, which allows you to create multi‐
    line strings without having to insert newline characters all over the place.
    */
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF
    
    /*
    The catch with the create_before_destroy parameter is that if you set it to true on 
    resource X, you also have to set it to true on every resource that X depends on.
    */
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "asg" {
    launch_configuration = "${aws_launch_configuration.launch-config.id}"
    // data.aws_availability_zones.all will fetch the AZs specific to your AWS account.
    availability_zones = ["${data.aws_availability_zones.available.names}"]

    load_balancers      = ["${aws_elb.elb.name}"]
    // Use the ELB’s health check to determine if an Instance is healthy or not.
    health_check_type   = "ELB"

    min_size = 2
    max_size = 6

    tag {
        key                 = "Name"
        value               = "terraform-asg-example"
        propagate_at_launch = true
    }
}

resource "aws_security_group" "web-sg" {
    name = "terraform-web-sg"

    ingress {
        from_port   = "${var.server_port}"
        to_port     = "${var.server_port}"
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_elb" "elb" {
    name                = "terraform-elb"
    availability_zones  = ["${data.aws_availability_zones.available.names}"]
    security_groups     = ["${aws_security_group.elb-sg.id}"]

    listener {
        lb_port             = 80
        lb_protocol         = "http"
        instance_port       = "${var.server_port}"
        instance_protocol   = "http"
    }

    health_check {
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 3
        interval            = 30
        target              = "HTTP:${var.server_port}/"
    }
}

resource "aws_security_group" "elb-sg" {
    name = "terraform-elb-sg"

    ingress {
        from_port   = 80
        to_port     = 80
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

# Declare the data source
data "aws_availability_zones" "available" {}

variable "server_port" {
    description = "The port the server will use for HTTP requests."
    default = 8080
}

output "elb_dns_name" {
    value = "${aws_elb.elb.dns_name}"
}