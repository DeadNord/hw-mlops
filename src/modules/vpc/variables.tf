variable "vpc_cidr_block" {
  description = "CIDR-блок VPC"
  type        = string
}

variable "public_subnets" {
  description = "Три CIDR-блоки для публічних підмереж"
  type        = list(string)
}

variable "private_subnets" {
  description = "Три CIDR-блоки для приватних підмереж"
  type        = list(string)
}

variable "availability_zones" {
  description = "Три AZ того самого реґіону"
  type        = list(string)
}

variable "vpc_name" {
  description = "Base name for all resources"
  type        = string
}

/*  optional  */
variable "nat_eip_allocation_id" {
  description = <<-EOT
    Існуючий Allocation ID Elastic IP для NAT-Gateway.
    Якщо порожній ("", default) – модуль створить новий EIP.
  EOT
  type        = string
  default     = ""
}
