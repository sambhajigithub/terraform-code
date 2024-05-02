resource "aws_instance" "this" {
    ami = "ami-04b70fa74e45c3917"
    instance_type = "t2.micro"
    subnet_id = values(aws_subnet.public)[0].id
    #key_name = "xyz.pem"

    vpc_security_group_ids = [aws_security_group.this.id]

    tags = merge(
    var.tags,
    {
      "Name" = "ec2-${var.name}"
    }
  )
}
  

resource "aws_vpc" "this" {
  cidr_block         = var.cidr_block
  enable_dns_support = true

  tags = merge(
    var.tags,
    {
      "Name" = "vpc-${var.name}"
    },
  )
}

resource "aws_subnet" "public" {
  for_each = { for az in var.availability_zones : az.availability_zones => az }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.public_subnet
  availability_zone = each.key

  tags = merge(
    var.tags,
    {
      "Name" = "subnet-public-${var.name}"
    },
  )
}

resource "aws_subnet" "private" {
  for_each = { for az in var.availability_zones : az.availability_zones => az }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.private_subnet
  availability_zone = each.key

  tags = merge(
    var.tags,
    {
      "Name" = "subnet-private-${var.name}"
    },
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      "Name" = "igw-${var.name}"
    },
  )
}

resource "aws_nat_gateway" "this" {
  subnet_id     = values(aws_subnet.public)[0].id
  allocation_id = aws_eip.this.id

  tags = merge(
    var.tags,
    {
      "Name" = "ngw-ext-${var.name}"
    },
  )
}

resource "aws_eip" "this" {
  tags = merge(
    var.tags,
    {
      "Name" = "eip-ngw-ext-${var.name}"
    },
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      "Name" = "rtb-private-${var.name}"
    },
  )
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      "Name" = "rtb-public-${var.name}"
    },
  )
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = values(aws_subnet.private)[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = values(aws_subnet.public)[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "this" {
  name        = "vpc-${var.name}"
  description = "Security group for vpc-${var.name}"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [for az in var.availability_zones : az.private_subnet]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      "Name" = "vpc-${var.name}"
    },
  )
}