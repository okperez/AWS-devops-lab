resource "aws_key_pair" "my_key" {
  key_name   = "my_key"
  public_key = file(pathexpand("~/.ssh/devops_pro.pub"))
}