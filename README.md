# terraform-stuff

To make this code work, create terraform.tfvars file with required variables or pass them from the command line.
Here is an example of terraform.tfvars:
aws_access_key       = "xxxx"
aws_secret_key       = "xxxxx"
aws_region           = "us-east-1"
vpc_cidr_range       = "10.0.0.0/16"
private_subnet_az    = "us-east-1a"
private_subnet_range = "10.0.1.0/24"
public_subnet_range  = "10.0.2.0/24"
public_subnet_az     = "us-east-1b"
