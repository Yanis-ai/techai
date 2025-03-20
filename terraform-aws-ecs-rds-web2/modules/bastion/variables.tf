variable "subnet_ids" {
  # EC2インスタンスを起動するサブネットIDのリストを指定します
  description = "List of subnet IDs where EC2 instances will be launched"

  # この変数のタイプは文字列リスト（list(string)）です
  type        = list(string)
}

variable "ec2_sg_id" {
  # この変数はEC2セキュリティグループのIDを指定します
  description = "The ID of the EC2 security group"

  # 変数のタイプは文字列（string）です
  type        = string
}
