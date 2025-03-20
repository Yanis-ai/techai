# データベースサブネットグループの名前を指定するための変数
variable "db_subnet_group_name" {
  description = "Name of the database subnet group" # データベースサブネットグループの名前を説明
  type        = string                   # 変数のタイプ（文字列のリスト）
}

# RDSインスタンス用のセキュリティグループIDリストを指定するための変数
variable "rds_security_group_ids" {
  description = "List of security group IDs for the RDS instance" # RDSインスタンスのセキュリティグループIDリストを説明
  type        = list(string)                                      # 変数のタイプ（文字列のリスト）
}
