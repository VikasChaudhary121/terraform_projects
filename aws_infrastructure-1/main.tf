# CREATING THE VIRTUAL PRIVATE CLOUD

resource "aws_vpc" "my_custom_vpc"{
	cidr_block = var.cidr
	tags = {
		Name = "my-custom"
}
}

# CREATING TWO AWS-SUBNET IN TWO DIFFERENT AVAILABILITY ZONESINSIDE THE VPC

resource "aws_subnet" "my_subnet_1" {
	vpc_id = aws_vpc.my_custom_vpc.id
	cidr_block = "10.0.0.0/24"
	availability_zone = "ap-south-1a"
	map_public_ip_on_launch = true
}

resource "aws_subnet" "my_subnet_2" {
	vpc_id = aws_vpc.my_custom_vpc.id
        cidr_block = "10.0.1.0/24"
        availability_zone = "ap-south-1b"
        map_public_ip_on_launch = true

}

# CREATING INTERNET GATEWAY 

resource "aws_internet_gateway" "my_gateway_1" {
        vpc_id = aws_vpc.my_custom_vpc.id
}

# CREATING ROUTE TABLE

resource "aws_route_table" "my_route_table_1" {
	vpc_id = aws_vpc.my_custom_vpc.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.my_gateway_1.id
		
	}
}

# associating the route_table with the subnets

resource "aws_route_table_association" "RTA-1" {
	subnet_id = aws_subnet.my_subnet_1.id
	route_table_id = aws_route_table.my_route_table_1.id
}

resource "aws_route_table_association" "RTA-2" {
        subnet_id = aws_subnet.my_subnet_2.id
        route_table_id = aws_route_table.my_route_table_1.id
}

# ADDING THE SECURITY GROUP

resource "aws_security_group" "my_scg_1" {
	name = "websg"
	vpc_id = aws_vpc.my_custom_vpc.id

# ADDING THE INBOUND RULE (ENGRESS) 

	ingress {
		description = "HTTPS"
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

        ingress {
		description = "SSH"
                from_port = 22
                to_port = 22
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }

# ADDING THE OUTBOUND RULE (EGRESS)
	
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	tags = {
		Name = "web-sg"
	}

}

# CREATING A S3 BUCKET

resource "aws_s3_bucket" "my_bucket_1" {
	bucket = "my-bucket-s3-43200500-tf"
}

# CREATING THE INSTANCES INSIDE THE SUBNETS

resource "aws_instance" "web_server_1" {
	instance_type = "t2.micro"
	ami = "ami-03f4878755434977f"
	vpc_security_group_ids = [aws_security_group.my_scg_1.id]
	subnet_id = aws_subnet.my_subnet_1.id
	user_data = base64encode(file("user_script_data1.sh"))
	tags = {
		Name = "web_server_1"
	}
}

resource "aws_instance" "web_server_2" {
        instance_type = "t2.micro"
        ami = "ami-03f4878755434977f"
        vpc_security_group_ids = [aws_security_group.my_scg_1.id]
        subnet_id = aws_subnet.my_subnet_2.id
        user_data = base64encode(file("user_script_data2.sh"))
        tags = {
                Name = "web_server_2"
        }
}

# CREATING A LOAD BALANCER

resource "aws_lb" "my_balancer" {
		name = "my-lbalancer-1"
		internal = false
		load_balancer_type = "application"
		security_groups = [aws_security_group.my_scg_1.id]
		subnets = [aws_subnet.my_subnet_1.id, aws_subnet.my_subnet_2.id]
}

# CREATING THE TARGET GROUP

resource "aws_lb_target_group" "my_target" {
		name = "myTG1"
		port = 80
		protocol = "HTTP"
		vpc_id = aws_vpc.my_custom_vpc.id
		
		health_check {
			path = "/"
			port = "traffic-port"
	}
}

# DEFINING WHAT SHOULD BE INSIDE THE TARGET GROUP

resource "aws_lb_target_group_attachment" "attach_item_1" {
	target_group_arn = aws_lb_target_group.my_target.arn
	target_id = aws_instance.web_server_1.id
	port = 80
}

resource "aws_lb_target_group_attachment" "attach_item_2" {
        target_group_arn = aws_lb_target_group.my_target.arn
        target_id = aws_instance.web_server_2.id
        port = 80

}

# ATTACHING THE LOAD BALANCER WITH THE TARGET GROUP BY DEFINEING THE LISTENER

resource "aws_lb_listener" "my_listener" {
	load_balancer_arn = aws_lb.my_balancer.arn
	port = 80
	protocol = "HTTP"
	
	default_action {
		target_group_arn = aws_lb_target_group.my_target.arn
		type = "forward"
	}
}

# OUTPUT TO DISPLAY ON THE TERMINAL AFTER THE INFRASTRUCTURE IS READY

output "load_balancer_dns" {
	value = aws_lb.my_balancer.dns_name
}
output "vpc_id" {
	value = aws_vpc.my_custom_vpc.id
}
output "instances_info" {
	value = {
		instance_1 = aws_instance.web_server_1.id
		instance_2 = aws_instance.web_server_2.id
	}
}
