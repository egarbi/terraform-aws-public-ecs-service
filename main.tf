/** 
* Variables
*/

variable "name" {}

variable "dns_name" {}

variable "alb_logs_expiration_enabled" {
  default = "true"
}
variable "alb_logs_expiration_days" {
  default = 90
}

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "subnet_ids" {
  type = "list"
  description = "List of subnets where LB live, tipically one per AZ"
}

variable "security_groups" {
  type = "list"
  description = "List of security group to associate with the LB"
}

variable "vpc_id" {}

variable "zone_id" {}

variable "ssl_arn" {}

variable "ssl_policy" {
  default = "ELBSecurityPolicy-2015-05"
}

variable "desired_count" {
  description = "How many task do you want to have running"
  default = 1
}

variable "cluster" {}

variable "service_iam_role" {}

variable "container_definitions" {}

variable "container_port" {}

variable "container_proto" {}


/** 
* Resources
*/

module "s3_logs" {
  source                  = "git::https://github.com/egarbi/terraform-aws-s3-logs?ref=0.0.2"
  name                    = "${var.name}"
  environment             = "${var.environment}"
  logs_expiration_enabled = "${var.alb_logs_expiration_enabled}"
  logs_expiration_days    = "${var.alb_logs_expiration_days}"
}


module "publicALB" {
  source                 = "git::https://github.com/egarbi/terraform-aws-alb-per-host?ref=0.0.1"
  name                = "${var.name}"
  subnet_ids          = "${var.subnet_ids}"
  environment         = "${var.environment}"
  security_groups     = "${var.security_groups}"
  vpc_id              = "${var.vpc_id}"
  log_bucket          = "${module.s3_logs.id}"
  zone_id             = "${var.zone_id}"
  ssl_arn             = "${var.ssl_arn}"
  ssl_policy          = "${var.ssl_policy}"
  hosts               = [ "${var.dns_name}" ]
  services            = [ "${var.name}" ]
  backend_port        = "${var.container_port}"
  backend_proto       = "${var.container_proto}"
}

module "ecs_service" {
  source          = "git::https://github.com/egarbi/terraform-aws-ecs-service?ref=1.0.3"
  name            = "${var.name}"
  environment     = "${var.environment}"
  desired_count   = "${var.desired_count}"
  cluster         = "${var.cluster}"
  iam_role        = "${var.service_iam_role}"
  target_group    = "${module.publicALB.target_groups[0]}"
  container_port  = "${var.container_port}"
  container_definitions = "${var.container_definitions}"
}
