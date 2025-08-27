#########################################
# VPC  +  підмережі  +  IGW
#########################################
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.vpc_name}-vpc" }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public-${count.index + 1}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.vpc_name}-private-${count.index + 1}"
    Tier = "private"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.vpc_name}-igw" }
}

#########################################
# NAT Gateway — один на VPC
#########################################

# 0 ✔  створюємо EIP, якщо ID не передано
resource "aws_eip" "nat" {
  count  = var.nat_eip_allocation_id == "" ? 1 : 0
  domain = "vpc"
  tags   = { Name = "${var.vpc_name}-nat-eip" }
}

# 1 ✔  визначаємо Allocation ID (створений або існуючий)
locals {
  # якщо передано готовий Allocation ID → використовуємо його
  # інакше — беремо ID EIP, який модуль щойно створить (count = 1)
  nat_allocation_id = var.nat_eip_allocation_id != "" ? var.nat_eip_allocation_id : aws_eip.nat[0].id
}


resource "aws_nat_gateway" "this" {
  allocation_id = local.nat_allocation_id
  subnet_id     = aws_subnet.public[0].id # перша public-subnet
  tags          = { Name = "${var.vpc_name}-nat" }
  depends_on    = [aws_internet_gateway.this]
}
