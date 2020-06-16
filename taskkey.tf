provider "aws" {
  region = "ap-south-1"
  shared_credentials_file = "C:/Users/Nadeem/.aws/credentials"
  profile = "nadimpro"
}

resource "tls_private_key" "task1_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "mypvkey" {
    depends_on = [tls_private_key.task1_key]
    content         =  tls_private_key.task1_key.private_key_pem
    filename        =  "task1.pem"
    file_permission =  0400
}

resource "aws_key_pair" "pubkey" {
  depends_on = [local_file.mypvkey]
  key_name   = "task1-key"
  public_key = tls_private_key.task1_key.public_key_openssh
}
