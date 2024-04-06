resource "aws_vpc" "trp-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }

}

resource "aws_subnet" "trp-public-subnet" {
  vpc_id                  = aws_vpc.trp-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public"
  }

}

resource "aws_internet_gateway" "trp-gw" {
  vpc_id = aws_vpc.trp-vpc.id

  tags = {
    Name = "dev-ig"
  }
}

resource "aws_route_table" "trp-route-table" {
  vpc_id = aws_vpc.trp-vpc.id


  tags = {
    Name = "dev-route-table"
  }
}

resource "aws_route" "trp-default-route" {
  route_table_id         = aws_route_table.trp-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.trp-gw.id
}

resource "aws_route_table_association" "trp-rta-a" {
  subnet_id      = aws_subnet.trp-public-subnet.id
  route_table_id = aws_route_table.trp-route-table.id
}

resource "aws_security_group" "trp-security-group" {
  name        = "dev-sg"
  description = "dev security group"
  vpc_id      = aws_vpc.trp-vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "trp-auth" {
  key_name   = "trp-key"
  public_key = file("~/.ssh/id_aws_ed25519.pub")
}


resource "aws_instance" "trp-dev" {
  instance_type = "t3.micro"
  ami           = data.aws_ami.trp-ami.id

  key_name = aws_key_pair.trp-auth.key_name
  vpc_security_group_ids = [aws_security_group.trp-security-group.id]
  subnet_id = aws_subnet.trp-public-subnet.id

  user_data =  file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "trp-dev-node"
  }
}