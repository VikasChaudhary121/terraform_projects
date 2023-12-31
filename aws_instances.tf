resource "aws_instance" "my_instances" {
	for_each = local.instances
	ami = "ami-0a0f1259dd1c90938"
	instance_type = "t2.micro"
	tags= {
		Name = each.key
	}
}

provider "aws" {
	region = "ap-south-1"
}

locals {
	instances = toset(["docker","terraform","ansible","jenkins","maven"])
}
