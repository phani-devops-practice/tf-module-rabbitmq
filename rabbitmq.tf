resource "aws_spot_instance_request" "instance" {
  ami                    = data.aws_ami.ami.image_id
  spot_price             = data.aws_ec2_spot_price.spot_price.spot_price
  instance_type          = var.INSTANCE_TYPE
  wait_for_fulfillment   = true
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = var.PRIVATE_SUBNET_IDS[0]
  iam_instance_profile   = aws_iam_instance_profile.allow-secret-manager-read-access.name
  tags = {
    Name = local.TAG_PREFIX
  }
}

resource "aws_ec2_tag" "main" {
  resource_id = aws_spot_instance_request.instance.spot_instance_id
  key         = "Name"
  value       = local.TAG_PREFIX
}

resource "null_resource" "cluster" {

  provisioner "remote-exec" {
    connection {
      user = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_USER"]
      pass = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_PASS"]
      host = aws_spot_instance_request.instance.private_ip
    }
    inline = [
      "ansible-pull -U https://github.com/phani-devops-practice/TRN-roboshop-ansilble.git roboshop.yml -e HOST=localhost -e ROLE=rabbitmq -e ENV=${var.ENV}"
    ]
  }
}