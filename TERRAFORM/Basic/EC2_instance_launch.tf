provider "aws" {
    region = "ap-south-1"
    profile = "subuser1"
}

variable "key_name" {
    type = string
    default = "mywebserver3"
}

resource "aws_security_group" "sec_Grp" {
  
  name = "sg1"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource  "aws_instance" "myTfIn" {
    ami = "ami-0447a12f28fddb066"
    instance_type = "t2.micro"
    key_name = var.key_name
    security_groups = [ aws_security_group.sec_Grp.name ]

    connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/root_pie/Desktop/Summer_project_LW/AWS/mywebserver3.pem")
    host     = aws_instance.myTfIn.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]

  }

    tags = {
        Name = "myWebTfIn"
    }

}

output "myOutAz" {
    value = aws_instance.myTfIn.availability_zone
}

output "my_public_ip" {
    value = aws_instance.myTfIn.public_ip
}


resource "aws_ebs_volume" "myWebPd" {
  availability_zone = aws_instance.myTfIn.availability_zone
  size  = 1

  tags = {
    Name = "myWebTfPd"
  }
}

resource "aws_volume_attachment" "ebs_attatch" {

     depends_on = [
        aws_instance.myTfIn,
    ]
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.myWebPd.id
  instance_id = aws_instance.myTfIn.id
}

resource "null_resource" "remote_null_resource_1" {
    depends_on = [
        aws_volume_attachment.ebs_attatch,
    ]

    connection {
        type = "ssh"
        user = "ec2-user"
        private_key = file("C:/Users/root_pie/Desktop/Summer_project_LW/AWS/mywebserver3.pem")
        host = aws_instance.myTfIn.public_ip
    }

   
    provisioner "remote-exec" {
        inline = [
            "sudo mkfs.ext4  /dev/xvdh",
            "sudo mount  /dev/xvdh  /var/www/html",
            "sudo rm -rf /var/www/html/*",
            "sudo git clone https://github.com/shivam221201/Hybrid_Multi_Cloud.git /var/www/html/"
        ]

    }
}

resource "null_resource" "remote_null_resource_2"  {


depends_on = [
    null_resource.remote_null_resource_1,
  ]

	provisioner "local-exec" {
	    command = "start chrome  ${aws_instance.myTfIn.public_ip}"
  	}
}