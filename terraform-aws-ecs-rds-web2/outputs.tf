output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnets" {
  value =module.networking.public_subnets
}

output "private_subnets" {
  value = module.networking.private_subnets
}

# データベースエンドポイントを出力
output "db_endpoint" {
  value = module.database.db_endpoint # エンドポイントのホスト名を抽出して出力
}

# データベース名を出力
output "db_name" {
  value = module.database.db_name  # データベース名を出力
}

# データベースユーザー名を出力
output "db_username" {
  value = module.database.db_username  # データベースのユーザー名を出力
}

# ランダム生成されたデータベースパスワードを出力
output "db_password" {
  value     = module.database.db_password  # パスワードを出力
  sensitive = true                                # センシティブな情報としてマーク（UIで非表示）
}

# バスチョンインスタンスのパブリックIPを出力
output "bastion_pulic_ip" {
  value = module.bastion.bastion_pulic_ip
}
