provider "aws" {
  region     = "ap-south-1"
  profile    = "ashish"
}
/*resource "aws_key_pair" "deployer" {
  key_name   = "mykey1"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}
*/


resource "aws_security_group" "firewall" {
  name        = "firewall"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-9b4d51f3"

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
 ingress {
	    description = "SSH"
	    from_port   = 22
	    to_port     = 22
	    protocol    = "tcp"
	    cidr_blocks = [ "0.0.0.0/0" ]
	  }
 ingress {
	    description = "HTTP"
	    from_port   = 80
	    to_port     = 80
	    protocol    = "tcp"
	    cidr_blocks = [ "0.0.0.0/0" ]
	  }	



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "firewall"
  }
}


resource "aws_s3_bucket" "bucket1" {
  bucket = "ashish1469"
  acl    = "public-read"

versioning {
	enabled = false
}
tags = { 
	Environment = "Dev"
}
}


resource "aws_s3_bucket_object" "mybucket1" {
  bucket = "ashish1469"
  key    = "myimage.jpg"
  source = "C:/Users/ASHISH/Pictures/myimage.jpg"
 content_type = "image or jpg"
  acl    = "public-read"
 depends_on = [ aws_s3_bucket.bucket1 ]
}



resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "ashish1469.s3.amazonaws.com"
    origin_id   = "S3-myimage.jpg"

   custom_origin_config {
	http_port = 80
	https_port = 80
	origin_protocol_policy = "match-viewer"
	origin_ssl_protocols = ["TLSv1","TLSv1.1","TLSv1.2"]
	

  }
}


  enabled             = true

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id= "S3-myimage.jpg"
  

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


resource "aws_instance" "myinstance1" {
  depends_on = [ aws_cloudfront_distribution.s3_distribution ]
  ami           = "ami-052c08d70def0ac62"
  instance_type = "t2.micro"
  key_name = "mykey1111"
  security_groups = [ "launch-wizard-2" ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/ASHISH/Downloads/mykey1111.pem")
    host     = aws_instance.myinstance1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "Myworldos"
  }

}


resource "aws_ebs_volume"  "vol1" {
  	availability_zone = aws_instance.myinstance1.availability_zone
  	size              = 1

  tags = {
    Name = "firstvolume"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.vol1.id
  instance_id = aws_instance.myinstance1.id
}

output "myout3" {
	value = aws_instance.myinstance1.public_ip
 }


resource "null_resource" "nulllocater"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.myinstance1.public_ip} > publicip.txt"
  	}
}



resource "null_resource" "nullremote"  {

depends_on = [
    aws_volume_attachment.ebs_att,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/ASHISH/Downloads/mykey1111.pem")
    host     = aws_instance.myinstance1.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/ashish1469/cloud.git /var/www/html/"
    ]
  }
}



resource "null_resource" "nulllocal1"  {


depends_on = [
    null_resource.nullremote,
  ]

	provisioner "local-exec" {
	    command = "start chrome  ${aws_instance.myinstance1.public_ip}"
  	}
}


