# VPCを作成
resource "aws_vpc" "main" {
  # CIDRブロック範囲
  cidr_block = "10.0.0.0/16"

  # DNSサポートの有効化
  enable_dns_support   = true
  enable_dns_hostnames = true

  # タグ設定
  tags = {
    Name = "flask-app-vpc"
  }
}

# 利用可能なアベイラビリティゾーンを取得
data "aws_availability_zones" "available" {}

# パブリックサブネットを作成
resource "aws_subnet" "public" {
  # アベイラビリティゾーンの数だけ作成
  count                   = length(data.aws_availability_zones.available.names)

  # VPC IDを指定
  vpc_id                  = aws_vpc.main.id

  # CIDRブロックの範囲を計算
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)

  # アベイラビリティゾーンを指定
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)

  # 起動時にパブリックIPを割り当てる
  map_public_ip_on_launch = true

  # タグ設定
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

# プライベートサブネットを作成
resource "aws_subnet" "private" {
  # アベイラビリティゾーンの数だけ作成
  count             = length(data.aws_availability_zones.available.names)

  # VPC IDを指定
  vpc_id            = aws_vpc.main.id

  # CIDRブロックの範囲を計算
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + length(data.aws_availability_zones.available.names))

  # アベイラビリティゾーンを指定
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  # タグ設定
  tags = {
    Name = "private-subnet-${count.index}"
  }
}

# インターネットゲートウェイを作成
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# デフォルトルートを設定
resource "aws_route" "default_route" {
  # デフォルトのルートテーブルを使用
  route_table_id         = aws_vpc.main.default_route_table_id

  # 送信先CIDR範囲を設定
  destination_cidr_block = "0.0.0.0/0"

  # インターネットゲートウェイを指定
  gateway_id             = aws_internet_gateway.gw.id
}

# プライベートルートテーブルを作成
resource "aws_route_table" "private" {
  # VPC IDを指定
  vpc_id = aws_vpc.main.id

  # タグ設定
  tags = {
    Name = "private-route-table"
  }
}

# パブリックサブネットとルートテーブルを関連付け
resource "aws_route_table_association" "public" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_vpc.main.default_route_table_id
}

# プライベートサブネットとルートテーブルを関連付け
resource "aws_route_table_association" "private" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "ecs_sg" {
  # ECSサービス用のセキュリティグループを作成
  name        = "ecs-service-sg"          # セキュリティグループ名
  description = "Security group for ECS service" # セキュリティグループの説明
  vpc_id      = aws_vpc.main.id           # 対象のVPC ID

  # - 入力トラフィックルール
  ingress {
    from_port   = 5000                    # 開始ポート番号（5000）
    to_port     = 5000                    # 終了ポート番号（5000）
    protocol    = "tcp"                   # 通信プロトコル（TCP）
    cidr_blocks = ["0.0.0.0/0"]           # 許可するCIDR範囲（全世界）
                                           # 必要に応じて特定IPや範囲に調整可能
  }

  # - 出力トラフィックルール
  egress {
    from_port   = 0                       # 全ポート許可
    to_port     = 0
    protocol    = "-1"                    # すべてのプロトコルを許可
    cidr_blocks = ["0.0.0.0/0"]           # 許可する送信先範囲（全世界）
  }
}

resource "aws_security_group" "alb_sg" {
  # ALB（アプリケーションロードバランサー）用のセキュリティグループ
  name        = "alb-sg"                  # セキュリティグループ名
  description = "Security group for ALB" # セキュリティグループの説明
  vpc_id      = aws_vpc.main.id           # 対象のVPC ID

  # - 入力トラフィックルール
  ingress {
    from_port   = 80                      # HTTPポート番号（80）
    to_port     = 80
    protocol    = "tcp"                   # 通信プロトコル（TCP）
    cidr_blocks = ["0.0.0.0/0"]           # 許可するCIDR範囲（全世界）
                                           # 必要に応じて範囲を調整可能
  }

  ingress {
    from_port   = 443                     # HTTPSポート番号（443）
    to_port     = 443
    protocol    = "tcp"                   # 通信プロトコル（TCP）
    cidr_blocks = ["0.0.0.0/0"]           # 許可するCIDR範囲（全世界）
                                           # 必要に応じて範囲を調整可能
  }

  #  - 出力トラフィックルール
  egress {
    from_port   = 0                       # 全ポート許可
    to_port     = 0
    protocol    = "-1"                    # すべてのプロトコルを許可
    cidr_blocks = ["0.0.0.0/0"]           # 許可する送信先範囲（全世界）
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id           # 対象のVPC ID
  name = "rds_security_group"   # セキュリティグループの名前
  ingress {
    from_port   = 5432 # 許可する開始ポート（データベース用）
    to_port     = 5432 # 許可する終了ポート
    protocol    = "tcp"  # 通信プロトコル
    cidr_blocks = ["10.0.0.0/16"]  # 許可するCIDRブロック
  }

  egress {
    from_port   = 0 # 開始ポート（任意の範囲を許可）
    to_port     = 0 # 終了ポート
    protocol    = "-1"  # すべてのプロトコルを許可
    cidr_blocks = ["0.0.0.0/0"]  # すべてのIPアドレスを許可
  }

  tags = {
    Name = "rds_security_group" # タグ付け
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow HTTP and SSH access"
  vpc_id      = aws_vpc.main.id

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

resource "aws_db_subnet_group" "main" {
  # データベース用のサブネットグループを作成
  name       = "main-db-subnet-group"  # サブネットグループの名前
  subnet_ids = aws_subnet.public[*].id # 使用するプライベートサブネットのIDを指定
}

# 出力の定義
output "vpc_id" {
  # 作成されたVPCのIDを出力
  value = aws_vpc.main.id
}

output "public_subnets" {
  # 全てのパブリックサブネットIDを出力
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  # 全てのプライベートサブネットIDを出力
  value = aws_subnet.private[*].id
}

output "private_route_table" {
  # 作成されたプライベートルートテーブルのIDを出力
  value = aws_route_table.private.id
}

# ECSサービス用セキュリティグループのIDを出力
output "ecs_sg" {
  value = aws_security_group.ecs_sg.id  # セキュリティグループID
}

# ALB用セキュリティグループのIDを出力
output "alb_sg" {
  value = aws_security_group.alb_sg.id  # セキュリティグループID
}

# ec2用セキュリティグループのIDを出力
output "ec2_sg" {
  value = aws_security_group.ec2_sg.id  # セキュリティグループID
}

output "rds_sg" {
  value = aws_security_group.rds_sg.id  # セキュリティグループID
}


# データベースサブネットグループのIDを出力
output "db_subnet_group_name" {
  value = aws_db_subnet_group.main.name  # サブネットグループのIDを指定
}
