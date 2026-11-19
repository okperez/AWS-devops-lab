variable "ssh_ingress_cidr" {
  description = "Current public IPv4 address"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 instances"
  type        = string
}