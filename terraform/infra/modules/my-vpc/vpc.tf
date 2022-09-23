resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = "${
    tomap({
     "Name"= "terraform-eks-demo-node",
     "kubernetes.io/cluster/${var.cluster-name}"= "shared",
    })
  }"
}

data "aws_availability_zones" "available" {
all_availability_zones = true
}

resource "aws_subnet" "public" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.vpc.id}"

  tags = "${
    tomap({
     "Name"= "terraform-eks-demo-node",
     "kubernetes.io/cluster/${var.cluster-name}"= "shared",
    })
  }"
}

resource "aws_subnet" "private" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index+2}.0/24" # start the private subnet addresses right after the public ones
  vpc_id            = "${aws_vpc.vpc.id}"

  tags = "${
    tomap({
     "Name"= "terraform-eks-demo-node",
     "kubernetes.io/cluster/${var.cluster-name}"= "shared",
    })
  }"
}


resource "aws_internet_gateway" "mygateway" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "my_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mygateway.id
  }

}
resource "aws_route_table_association" "rta_subnet_public" {
  # for_each      = aws_subnet.public

  # subnet_id      = each.value.id
  count = 2
  subnet_id      = "${aws_subnet.public.*.id[count.index]}"

  route_table_id = aws_route_table.my_table.id
}


# Elastic-IP (eip) for NAT
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.mygateway]
}

# NAT gateway sits in first public subnet
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = "${aws_subnet.public.*.id[0]}"

  tags = {
    Name        = "nat gw"
    Environment = "${var.environment}"
  }

  depends_on = [aws_internet_gateway.mygateway]
}


resource "aws_route_table" "my_nat_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }

}
resource "aws_route_table_association" "rta_subnet_private" {
  # for_each      = aws_subnet.private
  # subnet_id      = each.value.id

  count = 2
  subnet_id      = "${aws_subnet.private.*.id[count.index]}"
  route_table_id = aws_route_table.my_nat_table.id
}
