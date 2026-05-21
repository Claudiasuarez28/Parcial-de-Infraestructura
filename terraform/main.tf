resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Permite HTTP desde internet"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Permite trafico desde ALB"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Permite PostgreSQL desde EC2"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

resource "aws_instance" "app_server_1" {
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true

  key_name = "infra-key"

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  user_data = file("user_data.sh")

  tags = {
    Name = "app-server-1"
  }
}

resource "aws_instance" "app_server_2" {
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet_2.id
  associate_public_ip_address = true

  key_name = "infra-key"

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  user_data = file("user_data.sh")

  tags = {
    Name = "app-server-2"
  }
}

resource "aws_lb" "app_alb" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb_sg.id
  ]

  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  tags = {
    Name = "application-load-balancer"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "app-target-group"
  }
}

resource "aws_lb_target_group_attachment" "app_1" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server_1.id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "app_2" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server_2.id
  port             = 3000
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
resource "aws_db_subnet_group" "db_subnets" {
  name       = "db-subnets"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = {
    Name = "db-subnets"
  }
}

resource "aws_db_instance" "postgres" {
  identifier        = "app-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "appdb"
  username = "admin"
  password = "Admin12345!"

  skip_final_snapshot = true

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]

  db_subnet_group_name = aws_db_subnet_group.db_subnets.name

  publicly_accessible = false
}