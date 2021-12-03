provider "aws" {
	region = "us-east-1"
}


data "aws_vpc" "default" {
	default = true
}

data "aws_subnet_ids" "all" {
	vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "allow_ssh" {
	name = "allow_ssh"
	vpc_id = data.aws_vpc.default.id
	
	ingress {
	  from_port   = 22
	  to_port     = 22
	  protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
	  from_port   = 0
	  to_port     = 0
	  protocol    = -1
	  cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "allow_internal" {
	name = "allow_internal"
	vpc_id = data.aws_vpc.default.id
	
	ingress {
	  from_port   = 0
	  to_port     = 0
          protocol    = -1
	  cidr_blocks = [data.aws_vpc.default.cidr_block]
	}
}

resource "aws_security_group" "allow_datadog_ports" {
	name = "allow_datadog_ports"
	vpc_id = data.aws_vpc.default.id
	
	ingress {
	  from_port   = 5000
	  to_port     = 5001
          protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "allow_dogstats" {
	name = "allow_dogstats"
	vpc_id = data.aws_vpc.default.id
	
	ingress {
	  from_port   = 8125
	  to_port     = 8125
          protocol    = "tcp"
	  cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_instance" "datadog-agent" {
	count 	      	       = 1
	ami           	       = "ami-0083662ba17882949"
	instance_type 	       = "t3.small"
	availability_zone      = "us-east-1a" 
	key_name      	       = "key"
	vpc_security_group_ids = [aws_security_group.allow_internal.id, aws_security_group.allow_ssh.id, aws_security_group.allow_dogstats.id, aws_security_group.allow_datadog_ports.id]
	
	connection {
		type = "ssh"
		host = self.public_ip 
		user = "centos"
		private_key = file("~/.ssh/key.pem") 
	}
	
	provisioner "file" {

		source = "."
		destination = "/tmp"
	}

	provisioner "remote-exec" {
		inline = [
			"echo 'api_key' > /tmp/api_key",
			"chmod +x /tmp/datadog-provision.sh",
			"sudo /tmp/datadog-provision.sh",
		]
	}
}

