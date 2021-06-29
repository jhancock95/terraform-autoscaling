provider "aws" {
  region     = "us-east-1"
  access_key = "xxxxxxxxxx"
  secret_key = "xxxxxxxxxx"
}

resource "aws_vpc" "first_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "prod-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.first_vpc.id

  tags = {
    Name = "prod-igw"
  }
}

resource "aws_route_table" "prod_route_table" {
  vpc_id = aws_vpc.first_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod-rt"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.first_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "prod-subnet-1"
    Tier = "public"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id                  = aws_vpc.first_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "prod-subnet-2"
    Tier = "public"
  }
}

resource "aws_subnet" "subnet_3" {
  vpc_id                  = aws_vpc.first_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "prod-subnet-3"
    Tier = "public"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.prod_route_table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.prod_route_table.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.subnet_3.id
  route_table_id = aws_route_table.prod_route_table.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.first_vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

resource "aws_launch_template" "frontend" {
  name                   = "frontend"
  image_id               = "ami-0ee02acd56a52998e"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  user_data = base64encode("${file("apache_launch.sh")}")
}

resource "aws_lb" "loadbalancer" {
  name               = "loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id, aws_subnet.subnet_3.id]

  tags = {
    Environment = "production"
  }
}

resource "aws_autoscaling_group" "as_group_1" {
  vpc_zone_identifier = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id, aws_subnet.subnet_3.id]
  desired_capacity    = 2
  max_size            = 5
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.frontendhttp.arn]

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }
}

resource "aws_lb_target_group" "frontendhttp" {
  name     = "frontendhttp"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.first_vpc.id
}

resource "aws_lb_listener" "frontendhttp" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontendhttp.arn
  }
}
