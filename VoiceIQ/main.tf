# Specify the provider and access details
provider "aws" {
  aws_access_key = "${var.access_key}"
  aws_secret_key = "${var.secret_key}"
  region = "${var.aws_region}"

}

data "aws_region" "default" {}

resource "aws_route53_record" "www" {
  zone_id = "${var.dns_zone_id}"
  name = "webapp-voiceiq.com"
  type = "A"

  alias {
    name = ""${aws_elastic_beanstalk_environment.VoiceIqWebApp.cname}""
    zone_id = "${var.dns_zone_id[data.aws_region.default.name]}"
    evaluate_target_health = true
  }
}

resource "aws_elastic_beanstalk_environment" "VoiceIqWebApp" {
  name = "VoiceIqWebApp-${var.env}"
  application = "VoiceIqWebApp-${var.env}"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.7.1 running Java 8"
  description = "application version created by terraform"
  bucket      = "${data.aws_s3_bucket.webapplication.id}"
  key         = "${data.aws_s3_bucket_object.application-jar.key}"
  
  data "aws_s3_bucket" "webapplication" {
  bucket = "webapplication"
}

data "aws_s3_bucket_object" "application-jar" {
  bucket = "${data.aws_s3_bucket.webapplication.id}"
  key    = "voiceiq/packages/voiceiqwebapp.jar"
}

  setting {
    namespace = "aws:ec2:vpc"
    name = "VPCId"
    value = "${var.vpc_details}"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "AssociatePublicIpAddress"
    value = "true"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "Subnets"
    value = ["${join(",", var.pub_subnets)}"]
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBSubnets"
    value = ["${join(",", var.pub_subnets)}"]
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "${var.instance_type}"
  }
   setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "${var.access_key}"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name = "Availability Zones"
    value = "Any 2"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name = "MinSize"
    value = "${var.min}"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name = "MaxSize"
    value = "${var.max}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "environment"
    value = "${var.env}"
  }
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name = "MaxBatchSize"
    value = "1"
  }
  setting {
    namespace = "aws:elb:loadbalancer"
    name = "CrossZone"
    value = "true"
  }
  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "SecurityGroups"
    value     = ["${aws_security_group.elb_sg.id}"]
  }
   setting {
    namespace = "aws:elb:listener"
    name      = "ListenerProtocol"
    value     = "HTTP"
  }
  setting {
    namespace = "aws:elb:listener"
    name      = "InstancePort"
    value     = "80"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name = "BatchSizeType"
    value = "Fixed"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name = "BatchSize"
    value = "1"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name = "DeploymentPolicy"
    value = "Rolling"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = [ "${aws_security_group.webapp_sg.id}" ]
  }
}
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "CPUUtilization"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Statistic"
    value     = "Average"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = "Percent"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "${var.autoscale_lower_bound}"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "${var.autoscale_upper_bound}"
  }
  

resource "aws_instance" "VoiceIqDB" {
  ami = "${var.aws_amis}"
  instance_type = "${var.instance_type}"
  subnet_id = "${var.prv_subnet}"
  user_data = "${file("userdata.sh")}"
  key_name = "${var.access_key}"
  security_groups =[ "${aws_security_group.db_sg.id}" ]
  tag {
    key                 = "Name"
    value               = "VoiceIqDB-${var.env}"
    propagate_at_launch = "true"
  }
}

# Security group for application service access
# the instances over SSH and HTTP
resource "aws_security_group" "db_sg" {
  name        = "VoiceIqDB_sg-${var.env}"
  description = "Security group for application services"
  vpc_id = "${var.vpc_details}"

  # SSH access from vpn
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  #Enabling access to mysql port only from webapp security group.
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = ["${aws_security_group.webapp_sg.id}"]
  }
  # Outbound Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#ELB security group
resource "aws_security_group" "elb_sg" {
  name        = "elb-${var.env}"
  description = "Security group for elbs exposed to outside"
  vpc_id      = "${var.vpc_details}"

  # HTTP access from anywhere
 ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
}

# A security group for the web
resource "aws_security_group" "webapp_sg" {
  name        = "webapp-${var.env}"
  description = "Security group for webapp exposed to outside"
  vpc_id      = "${var.vpc_details}"

  # HTTP access from anywhere
 ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


