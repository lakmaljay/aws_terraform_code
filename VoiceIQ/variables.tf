variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "us-east-1"
}

# ubuntu-trusty-16.04 (x64)
variable "aws_amis" {
  default = {
    "us-east-1" = "ami-d1689bc7"
  }
}

variable "dns_zone_id" {
  default = "ZXXIT4LG4QBV6"
  description = "Route 53 zone id"
}

variable "availability_zones" {
  default     = "us-east-1a,us-east-1b"
  description = "List of availability zones, use AWS CLI to find your "
}

variable "pub_subnets" {
  default = "subnet-1dxxxxx,subnet-bxxxxdc"
}

variable "prv_subnets" {
  default = "subnet-edxxxxxx,subnet-8dxxxxxx"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "AWS instance type"
}

variable "min" {
  description = "Min numbers of servers in ASG"
  default     = "2"
}

variable "max" {
  description = "Max numbers of servers in ASG"
  default     = "4"
}

variable "desired" {
  description = "Desired numbers of servers in ASG"
  default     = "2"
}

variable "access_key" {
  default = "webapp_prd_access"
}
variable "autoscale_lower_bound" {
  default     = "20"
  description = "Minimum level of autoscale metric to add instance"
}

variable "autoscale_upper_bound" {
  default     = "80"
  description = "Maximum level of autoscale metric to remove instance"
}


variable "region_s" {
  default = "usw2"
}

variable "vpc_details" {
  default = "vpc-385def51"
}

variable "env" {
  description = "Defines the environment"
  default = "prd"
}
