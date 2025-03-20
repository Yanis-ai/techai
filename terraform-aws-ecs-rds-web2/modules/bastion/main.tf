# SSHプライベートキーを生成する
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# プライベートキーをローカルファイルに保存する
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/private_key.pem"
  file_permission = "0600"
}

# 生成されたSSH公開キーを使用してAWSのSSHキーペアを作成するresource "aws_key_pair" "ssh_key_pair" 
resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "key-for-ec2-web"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# バスチョン用のEC2インスタンス
resource "aws_instance" "bastion" {
  # AMIはAmazon Linux 2023を使用
  ami           = "ami-0599b6e53ca798bb2" # Amazon Linux 2023
  
  # インスタンスタイプを指定
  instance_type = "t3.micro"
  
  # サブネットIDを変数から取得（最初のサブネット）
  subnet_id     = var.subnet_ids[0]
  
  # EC2インスタンスで使用するキーペア名を指定
  key_name      = aws_key_pair.ssh_key_pair.key_name
  
  # パブリックIPアドレスを関連付ける
  associate_public_ip_address = true

  # セキュリティグループIDを指定
  security_groups = [ var.ec2_sg_id ]

  # タグを設定
  tags = {
    Name = "bastion-server-instance" # インスタンスの名前
  }
}

resource "time_sleep" "wait_for_bastion" {
  create_duration = "30s"
}

# スクリプトをEC2インスタンスにアップロードする
resource "null_resource" "upload_sql" {
  depends_on = [ aws_instance.bastion, time_sleep.wait_for_bastion ]  

  provisioner "file" {
    source = "./${path.root}/create.sql"
    destination = "/tmp/create.sql"

    connection {
      type = "ssh"
      host = aws_instance.bastion.public_ip
      user = "ec2-user"
      private_key = tls_private_key.ssh_key.private_key_pem
      timeout      = "5m"
    }
  }
}

# バスチョンインスタンスのパブリックIPを出力
output "bastion_pulic_ip" {
  value = aws_instance.bastion.public_ip
}

output "tls_private_key" {
  value = tls_private_key.ssh_key.private_key_pem
}
