provider "aws" {
  # AWSプロバイダーを設定
  # リージョンは変数 `aws_region` から取得
  region = var.aws_region
}

module "networking" {
  # ネットワーク関連のモジュールを呼び出し
  # モジュールのソースは "./modules/networking" から取得
  source = "./modules/networking"
}

module "database" {
  # このモジュールは module.networking に依存しています
  depends_on = [ module.networking ]

  # データベースモジュールのパスを指定します
  source     = "./modules/database"

  # データベース用のサブネットグループ名を指定します
  db_subnet_group_name = module.networking.db_subnet_group_name

  # RDS（リレーショナルデータベースサービス）のセキュリティグループIDを設定します
  rds_security_group_ids = [ module.networking.rds_sg ]
}

module "bastion" {
  # このモジュールは「networking」モジュールに依存しています
  depends_on = [ module.database ]

  # モジュールのソースディレクトリを指定
  source = "./modules/bastion"

  # EC2セキュリティグループのIDを指定
  ec2_sg_id = module.networking.ec2_sg

  # 使用するパブリックサブネットのIDを指定
  subnet_ids = module.networking.public_subnets
}

resource "time_sleep" "wait_for_30" {
  create_duration = "30s"
}
# アップロードしたスクリプトをEC2インスタンスで実行する
resource "null_resource" "ssh_execute" {
  depends_on = [ module.bastion, time_sleep.wait_for_30 ]

  provisioner "remote-exec" {
    inline = [ 
      "sudo dnf update -y",
      "sudo dnf install -y postgresql16",
      "psql --version",
      "sudo psql -h ${module.database.rds_endpoint} -p 5432 -U ${module.database.db_username} -d ${module.database.db_name} -f /tmp/create.sql"
     ]

    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = module.bastion.tls_private_key
      host = module.bastion.bastion_pulic_ip
    }
  }
}

module "iamrole" {
  depends_on = [ null_resource.ssh_execute  ]

  source = "./modules/iamrole"
}

