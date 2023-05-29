resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "MY-VPC"
  }
}

#pub subnet

resource "aws_subnet" "mysubpub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone  = "ap-south-1a"

  tags = {
    Name = "MY-SUB-PUB"
  }
}

#pvt subnet

resource "aws_subnet" "mysubpvt" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone  = "ap-south-1b"

  tags = {
    Name = "MY-SUB-PVT"
  }
}

#IGW
resource "aws_internet_gateway" "tgw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "MT-IGW"
  }
}

#pub RT
resource "aws_route_table" "myrtpub" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tgw.id
  }

  tags = {
    Name = "MY-RT-PUB"
  }
}

#pvt RT
resource "aws_route_table" "myrtpvt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.myngw.id
  }

  tags = {
    Name = "MY-RT-PVT"
  }
}
#pubassco
resource "aws_route_table_association" "pubrtassco" {
  subnet_id      = aws_subnet.mysubpub.id
  route_table_id = aws_route_table.myrtpub.id
}

#pvtassco

resource "aws_route_table_association" "pvtrtassco" {
  subnet_id      = aws_subnet.mysubpvt.id
  route_table_id = aws_route_table.myrtpvt.id
}


resource "aws_security_group" "mysg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
    ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "MY-SEC-PUB"
  }
}

resource "aws_eip" "myeip" {
  #instance = aws_instance.web.id
  vpc      = true
}

resource "aws_nat_gateway" "myngw" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.mysubpub.id

  tags = {
    Name = "gw NAT"
  }

}

resource "aws_instance" "webserver" {
  ami           = "ami-076e3a557efe1aa9c"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.mysubpub.id
  vpc_security_group_ids = ["${aws_security_group.mysg.id}"]
  associate_public_ip_address = true

  tags = {
    Name = "webserver"
  }
}

resource "aws_instance" "DB" {
  ami           = "ami-076e3a557efe1aa9c"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.mysubpvt.id
  vpc_security_group_ids = ["${aws_security_group.mysg.id}"]
  #associate_public_ip_address = true

  tags = {
    Name = "DBserver"
  }
}


