resource "aws_vpc" "practice_terrafrom_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "practice_terrafrom_vpc"
  }
}

resource "aws_subnet" "practice_terrafrom_public_subnet_1a" {
  vpc_id = aws_vpc.practice_terrafrom_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "practice_terrafrom_public_subnet_1a"
  }
}

resource "aws_subnet" "practice_terrafrom_public_subnet_1c" {
  vpc_id = aws_vpc.practice_terrafrom_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "practice_terrafrom_public_subnet_1c"
  }
}

resource "aws_subnet" "practice_terrafrom_private_subnet_1a" {
  vpc_id            = aws_vpc.practice_terrafrom_vpc.id
  cidr_block        = "10.0.65.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "practice_terrafrom_private_subnet_1a"
  }
}

resource "aws_subnet" "practice_terrafrom_private_subnet_1c" {
  vpc_id            = aws_vpc.practice_terrafrom_vpc.id
  cidr_block        = "10.0.66.0/24"
  availability_zone = "ap-northeast-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "practice_terrafrom_private_subnet_1c"
  }
}

resource "aws_internet_gateway" "practice_terrafrom_igw" {
  vpc_id = aws_vpc.practice_terrafrom_vpc.id

  tags = {
    Name = "practice_terrafrom_igw"
  }
}

resource "aws_route_table" "practice_terrafrom_public_rt" {
  vpc_id = aws_vpc.practice_terrafrom_vpc.id

  tags = {
    Name = "practice_terrafrom_public_rt"
  }
}

resource "aws_route_table" "practice_terrafrom_private_rt_1a" {
  vpc_id = aws_vpc.practice_terrafrom_vpc.id

  tags = {
    Name = "practice_terrafrom_private_rt_1a"
  }
}

resource "aws_route_table" "practice_terrafrom_private_rt_1c" {
  vpc_id = aws_vpc.practice_terrafrom_vpc.id

  tags = {
    Name = "practice_terrafrom_private_rt_1c"
  }
}

resource "aws_route" "practice_terrafrom_public_r" {
  route_table_id = aws_route_table.practice_terrafrom_public_rt.id
  gateway_id     = aws_internet_gateway.practice_terrafrom_igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "practice_terrafrom_private_r_1a" {
  route_table_id = aws_route_table.practice_terrafrom_private_rt_1a.id
  nat_gateway_id = aws_nat_gateway.practice_terrafrom_nat_gateway_1a.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "practice_terrafrom_private_r_1c" {
  route_table_id = aws_route_table.practice_terrafrom_private_rt_1c.id
  nat_gateway_id = aws_nat_gateway.practice_terrafrom_nat_gateway_1c.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "practice_terrafrom_public_1a_rta" {
  subnet_id      = aws_subnet.practice_terrafrom_public_subnet_1a.id
  route_table_id = aws_route_table.practice_terrafrom_public_rt.id
}

resource "aws_route_table_association" "practice_terrafrom_public_1c_rta" {
  subnet_id      = aws_subnet.practice_terrafrom_public_subnet_1c.id
  route_table_id = aws_route_table.practice_terrafrom_public_rt.id
}

resource "aws_route_table_association" "practice_terrafrom_private_1a_rta" {
  subnet_id      = aws_subnet.practice_terrafrom_private_subnet_1a.id
  route_table_id = aws_route_table.practice_terrafrom_private_rt_1a.id
}

resource "aws_route_table_association" "practice_terrafrom_private_1c_rta" {
  subnet_id      = aws_subnet.practice_terrafrom_private_subnet_1c.id
  route_table_id = aws_route_table.practice_terrafrom_private_rt_1c.id
}

resource "aws_eip" "practice_terrafrom_eip_1a" {
  vpc = true
  depends_on = [aws_internet_gateway.practice_terrafrom_igw]

  tags = {
    Name = "practice_terrafrom_eip_1a"
  }
}

resource "aws_eip" "practice_terrafrom_eip_1c" {
  vpc = true
  depends_on = [aws_internet_gateway.practice_terrafrom_igw]

  tags = {
    Name = "practice_terrafrom_eip_1c"
  }
}

resource "aws_nat_gateway" "practice_terrafrom_nat_gateway_1a" {
  allocation_id = aws_eip.practice_terrafrom_eip_1a.id
  subnet_id     = aws_subnet.practice_terrafrom_public_subnet_1a.id
  depends_on = [aws_internet_gateway.practice_terrafrom_igw]

  tags = {
    Name = "practice_terrafrom_nat_gateway_1a"
  }
}

resource "aws_nat_gateway" "practice_terrafrom_nat_gateway_1c" {
  allocation_id = aws_eip.practice_terrafrom_eip_1c.id
  subnet_id     = aws_subnet.practice_terrafrom_public_subnet_1c.id
  depends_on = [aws_internet_gateway.practice_terrafrom_igw]

  tags = {
    Name = "practice_terrafrom_nat_gateway_1c"
  }
}

resource "aws_security_group" "practice_terrafrom_sg" {
  name   = "practice_terrafrom_sg"
  vpc_id = aws_vpc.practice_terrafrom_vpc.id

  tags = {
    Name = "practice_terrafrom_sg"
  }
}

resource "aws_security_group_rule" "practice_terrafrom_sg_ingress" {
  type = "ingress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.practice_terrafrom_sg.id
}

resource "aws_security_group_rule" "practice_terrafrom_sg_egress" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.practice_terrafrom_sg.id
}