provider "aws" {
  region = "ap-south-1"
  profile = "nadimpro"
}
resource "aws_security_group" "Security_Group" {
  name         = "mysecuretask1"
  description  = "HTTP Access"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  } 
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "myin2" {
  ami = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "task1-key"
  security_groups = [ "mysecuretask1" ]
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("H:/terraform_code/Key/task1.pem")
    host = aws_instance.myin2.public_ip
}
 provisioner "remote-exec" {
  inline = [
   "sudo yum install httpd php git -y",
   "sudo systemctl start httpd",
   "sudo systemctl enable httpd",  
  ]
}
  tags = {
    Name = "myos"
  }
}

resource "aws_ebs_volume" "ebs_volume" {
  availability_zone = aws_instance.myin2.availability_zone
  size = 1
  tags = {
    Name = "myebs1"
  }
}
resource "aws_volume_attachment" "ebs-att" {
  depends_on = [aws_ebs_volume.ebs_volume]
  device_name = "/dev/sdd"
  volume_id = aws_ebs_volume.ebs_volume.id
  instance_id = aws_instance.myin2.id
  force_detach = true
} 
resource "null_resource" "nullremote" {
depends_on = [aws_volume_attachment.ebs-att]
connection {
type = "ssh"
user = "ec2-user"
private_key = file("H:/terraform_code/Key/task1.pem")
host = aws_instance.myin2.public_ip
}
provisioner "remote-exec" {
inline = [
"sudo mkfs.ext4 /dev/xvdd",
"sudo mount /dev/xvdd /var/www/html",
"sudo rm -rf /var/www/html/*",
"sudo git clone https://github.com/nadim70/terraform.git /var/www/html/"
]
}
}


resource "aws_s3_bucket" "bucketman" {
  depends_on = [aws_instance.myin2]
  bucket = "nadim72-bucket"
  acl = "public-read"
provisioner "local-exec" {
    command = "git clone https://github.com/nadim70/terraform.git webphp"
  } 
}

resource "aws_s3_bucket_object" "object" {
  depends_on = [aws_s3_bucket.bucketman]
  bucket = "nadim72-bucket"
  key    = "terra.png"
  source = "H:/terraform_code/task1/webphp/terra.png"
  #etag = "${filemd5("terra.png")}"
  acl = "public-read"
  content_type = "image/png"
}

resource "aws_cloudfront_distribution" "s3_cloudfront" {
    enabled       = true 
    viewer_certificate {
    cloudfront_default_certificate = true
     }
    
    default_cache_behavior {
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "s3-bucket"
        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
    }    


    origin {
    domain_name = aws_s3_bucket.bucketman.bucket_domain_name
    origin_id   = "s3-bucket"
         }
}

output "myout" {
	value= aws_cloudfront_distribution.s3_cloudfront
}

resource "null_resource" "mounting_downloading" {
  connection {
        type     = "ssh"
        user     = "ec2-user"
	private_key = file("H:/terraform_code/Key/task1.pem")
        host     = aws_instance.myin2.public_ip
     }
provisioner "remote-exec" {
inline = [
"sudo chmod -R 777 /var/www/html",
"sudo echo '<img src='https://${aws_cloudfront_distribution.s3_cloudfront.domain_name}/terra.png' width='128' height='128'>'  >> /var/www/html/index.html" 
]
}
}
