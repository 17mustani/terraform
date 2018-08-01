resource "aws_security_group" "webservers" {
  name = "allow_http"
  description = "allow http inbound traffic"
  vpc_id = "${aws_vpc.vpc-main.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

