resource "aws_key_pair" "ssh_public_key" {
  key_name   = "my_key"
  public_key = var.ssh_public_key
}