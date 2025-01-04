terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Define the AWS provider
provider "aws" {
  region = "us-east-1" # Change to your preferred AWS region
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "seenu-vpc"
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count                   = 2 # Create two public subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "seenu-public-subnet-${count.index}"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "seenu-internet-gateway"
  }
}

# Create a route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "seenu-public-route-table"
  }
}

# Associate the public route table with the public subnets
resource "aws_route_table_association" "public" {
  count          = 2 # Associate with two public subnets
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}
