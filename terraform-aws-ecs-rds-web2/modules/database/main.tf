# ランダムなパスワードを生成
resource "random_password" "db_password" {
  length  = 16          # パスワードの長さ（16文字）
  special = false       # 特殊文字を使用しない
}

# PostgreSQLデータベースインスタンスを作成
resource "aws_db_instance" "main" {
  identifier = "flask-web-postgresql"      # データベースインスタンスの識別子
  allocated_storage      = 20             # ストレージ容量（GB単位）
  engine                 = "postgres"     # データベースエンジンの種類（PostgreSQL）
  engine_version         = "12.15"        # データベースエンジンのバージョン
  instance_class         = "db.t3.micro"  # インスタンスのクラス
  db_name                = "appdb"        # データベースの名前
  username               = "postgres"     # データベースのユーザー名
  password               = random_password.db_password.result  # ランダム生成されたパスワード
  db_subnet_group_name   = var.db_subnet_group_name            # データベースサブネットグループの名前
  vpc_security_group_ids = var.rds_security_group_ids          # VPCセキュリティグループ
  skip_final_snapshot    = true          # 終了時のスナップショットをスキップ
  multi_az               = false         # マルチAZを無効化（シングルAZで動作）

  tags = {
    Name = "test-web-postgresql"          # タグ：リソース名
  }
}

# データベースエンドポイントを出力
output "db_endpoint" {
  value = aws_db_instance.main.address # エンドポイントのホスト名を抽出して出力
}

# データベース名を出力
output "db_name" {
  value = aws_db_instance.main.db_name  # データベース名を出力
}

# データベースユーザー名を出力
output "db_username" {
  value = aws_db_instance.main.username  # データベースのユーザー名を出力
}

# ランダム生成されたデータベースパスワードを出力
output "db_password" {
  value     = random_password.db_password.result  # パスワードを出力
  sensitive = true                                # センシティブな情報としてマーク（UIで非表示）
}
