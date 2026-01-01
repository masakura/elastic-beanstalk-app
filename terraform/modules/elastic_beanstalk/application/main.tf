variable "project" {
  type = string
}

resource "aws_elastic_beanstalk_application" "application" {
  name = "${var.project}-application"
  tags = { Name = "${var.project}-application" }
}

output "application_name" {
  value = aws_elastic_beanstalk_application.application.name
}
