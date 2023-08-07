## この章の目標
![network](imgs/network.png)

この章では上記の図の通りのVPCリソースを構築します。  
3つのAvailability Zone で設計したときのネットワークが目標です。

Terraformで実際に記述していきましょう。

## 準備
新しいTerminalを立ち上げ、以下のコマンドでこの章用のディレクトリを作成し、作成したディレクトリに移動してください。  
```console
$ cd ~/Desktop/terraform-handson
$ mkdir handson
$ cd handson
```

Terraformを立ち上げているTerminalにもディレクトリが作成されていることを確認し、共有されたディレクトリに移動してください。
```console
# cd /terraform
# ls
handson     vpc-handson
# cd handson
```

プロバイダの定義を行います。今回もAWSを使用するので、"aws"と指定します。  
以下のコードを `main.tf` の命名で `handson/` 配下に作成してください。
```ruby
provider "aws" {
  region = "ap-northeast-1"
}
```

terraformの初期化を行います。

```console
# terraform init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v5.10.0...
- Installed hashicorp/aws v5.10.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

## VPC
![vpc](imgs/network-vpc.png)
まずは今回使用するVPCの作成を行います。

以下のコードを `main.tf` へ追記してください
```ruby
# VPC
# https://www.terraform.io/docs/providers/aws/r/vpc.html
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "handson"
  }
}
```

コードの追記が追えたらplanを行ってから適用を行います。
```console
# terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions
are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.0.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = (known after apply)
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + tags                                 = {
          + "Name" = "handson"
        }
      + tags_all                             = {
          + "Name" = "handson"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take
exactly these actions if you run "terraform apply" now.
```
```console
# terraform apply
  :
```

実際にVPCが作成されたかの確認をしましょう。

![vpc-list](imgs/vpc-list.png)
[https://ap-northeast-1.console.aws.amazon.com/vpc/home?region=ap-northeast-1#vpcs:sort=desc:VpcId](https://ap-northeast-1.console.aws.amazon.com/vpc/home?region=ap-northeast-1#vpcs:sort=desc:VpcId)

## Subnet
![subnet](imgs/network-subnet.png)
次にサブネットを6つ作成します。  
Public SubnetとPrivate Subnetの2種類と、ap-northeast-1リージョン(東京リージョン)に存在する3つのAZへ各種リソース(EC2やECSやRDSなど)を配置したいため、2*3で計6つのサブネットを作成します。

まずは「"handson-public-1a"という命名でap-northeast-1aにCIDRが10.0.1.0/24のサブネット」を作成してみましょう
```ruby
# Subnet
# https://www.terraform.io/docs/providers/aws/r/subnet.html
resource "aws_subnet" "public_1a" {
  # 先程作成したVPCを参照し、そのVPC内にSubnetを立てる
  vpc_id = aws_vpc.main.id

  # Subnetを作成するAZ
  availability_zone = "ap-northeast-1a"

  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "handson-public-1a"
  }
}
```

planを実行し、Subnetが作成されることを確認しましょう。
```console
# terraform plan
aws_vpc.main: Refreshing state... [id=vpc-04a9a87caaa295f60]

Terraform used the selected providers to generate the following execution plan. Resource actions
are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_subnet.public_1a will be created
  + resource "aws_subnet" "public_1a" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "ap-northeast-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.1.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Name" = "handson-public-1a"
        }
      + tags_all                                       = {
          + "Name" = "handson-public-1a"
        }
      + vpc_id                                         = "vpc-04a9a87caaa295f60"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take
exactly these actions if you run "terraform apply" now.
```

問題なければapplyを実行してSubnetの作成を行います。
```console
# terraform apply
  :
```

以下のコードを追記して、残り5つのサブネットも作成します。  
リソース名（e.g. "publi\_1c", "public\_1d"）と各種プロパティが少しずつことなるので注意してください。
```ruby
resource "aws_subnet" "public_1c" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1c"

  cidr_block        = "10.0.2.0/24"

  tags = {
    Name = "handson-public-1c"
  }
}

resource "aws_subnet" "public_1d" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1d"

  cidr_block        = "10.0.3.0/24"

  tags = {
    Name = "handson-public-1d"
  }
}

# Private Subnets
resource "aws_subnet" "private_1a" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.10.0/24"

  tags = {
    Name = "handson-private-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1c"
  cidr_block        = "10.0.20.0/24"

  tags = {
    Name = "handson-private-1c"
  }
}

resource "aws_subnet" "private_1d" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1d"
  cidr_block        = "10.0.30.0/24"

  tags = {
    Name = "handson-private-1d"
  }
}
```

planを実行し、5つの新しいリソースが追加されることを確認しましょう。
```console
# terraform plan
  :
Plan: 5 to add, 0 to change, 0 to destroy.
```

問題なければapplyを実行してSubnetの作成を行います。
```console
# terraform apply
```

WebコンソールからSubnetが6つ作成されていることを確認しましょう。  
サイドバーのVPCでフィルタリングで先程Terraformから作成した "handson" というVPCを選択すると分かりやすいです。

![subnets](imgs/subnet-list.png)
[https://ap-northeast-1.console.aws.amazon.com/vpc/home?region=ap-northeast-1#subnets:sort=tag:Name](https://ap-northeast-1.console.aws.amazon.com/vpc/home?region=ap-northeast-1#subnets:sort=tag:Name)

## Internet Gateway
![subnet](imgs/network-igw.png)
VPCからインターネットへの出入り口となるInternet Gatewayを作成しましょう。  
コンソール上から作成するとInternet Gateway とVPCは自動で紐付きませんが、Terraformの場合プロパティでVPCを指定することで自動的に紐づけてくれます。

```ruby
# Internet Gateway
# https://www.terraform.io/docs/providers/aws/r/internet_gateway.html
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson"
  }
}
```

planを実行し、1つのリソースが追加されていることを確認します。
```console
# terraform plan
Plan: 1 to add, 0 to change, 0 to destroy.
```

問題なければapplyを実行します。
```console
# terraform apply
```

## NAT Gateway
![subnet](imgs/network-natgw.png)
プライベートサブネットからインターネットへ通信するためにNAT Gatewayを使用します。  
NAT Gatewayは1つのElastic IPが必要なのでその割り当てと、AZ毎に必要なので3つ作成します。

まずはap-northeast-1a用のNAT Gatewayを1つ作成してみましょう
```ruby
# Elasti IP
# https://www.terraform.io/docs/providers/aws/r/eip.html
resource "aws_eip" "nat_1a" {
  domain = "vpc"

  tags = {
    Name = "handson-natgw-1a"
  }
}

# NAT Gateway
# https://www.terraform.io/docs/providers/aws/r/nat_gateway.html
resource "aws_nat_gateway" "nat_1a" {
  subnet_id     = aws_subnet.public_1a.id # NAT Gatewayを配置するSubnetを指定
  allocation_id = aws_eip.nat_1a.id       # 紐付けるElasti IP

  tags = {
    Name = "handson-1a"
  }
}
```

planで変更確認を行います。
```console
# terraform plan
aws_vpc.main: Refreshing state... [id=vpc-04a9a87caaa295f60]
aws_subnet.public_1a: Refreshing state... [id=subnet-041960c1f8a5b967d]
aws_subnet.public_1d: Refreshing state... [id=subnet-0a46037c64c900068]
aws_internet_gateway.main: Refreshing state... [id=igw-0d984cbd5a7fd3fe9]
aws_subnet.private_1c: Refreshing state... [id=subnet-0662a557c1b84449f]
aws_subnet.private_1a: Refreshing state... [id=subnet-03f8dc92279c34bb6]
aws_subnet.public_1c: Refreshing state... [id=subnet-03863af3bcfc4bb08]
aws_subnet.private_1d: Refreshing state... [id=subnet-060ec4e0cf9bfe036]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_eip.nat_1a will be created
  + resource "aws_eip" "nat_1a" {
      + allocation_id        = (known after apply)
      + association_id       = (known after apply)
      + carrier_ip           = (known after apply)
      + customer_owned_ip    = (known after apply)
      + domain               = "vpc"
      + id                   = (known after apply)
      + instance             = (known after apply)
      + network_border_group = (known after apply)
      + network_interface    = (known after apply)
      + private_dns          = (known after apply)
      + private_ip           = (known after apply)
      + public_dns           = (known after apply)
      + public_ip            = (known after apply)
      + public_ipv4_pool     = (known after apply)
      + tags                 = {
          + "Name" = "handson-natgw-1a"
        }
      + tags_all             = {
          + "Name" = "handson-natgw-1a"
        }
      + vpc                  = (known after apply)
    }

  # aws_nat_gateway.nat_1a will be created
  + resource "aws_nat_gateway" "nat_1a" {
      + allocation_id                      = (known after apply)
      + association_id                     = (known after apply)
      + connectivity_type                  = "public"
      + id                                 = (known after apply)
      + network_interface_id               = (known after apply)
      + private_ip                         = (known after apply)
      + public_ip                          = (known after apply)
      + secondary_private_ip_address_count = (known after apply)
      + secondary_private_ip_addresses     = (known after apply)
      + subnet_id                          = "subnet-041960c1f8a5b967d"
      + tags                               = {
          + "Name" = "handson-1a"
        }
      + tags_all                           = {
          + "Name" = "handson-1a"
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform
apply" now.
```

Elastic IP とNAT Gateway の2つが作成されることが確認できました。

applyを実行します。
```console
# terraform apply
```

残り2つのNAT Gatewayも作成して適用しましょう
```ruby
resource "aws_eip" "nat_1c" {
  domain = "vpc"

  tags = {
    Name = "handson-natgw-1c"
  }
}

resource "aws_nat_gateway" "nat_1c" {
  subnet_id     = aws_subnet.public_1c.id
  allocation_id = aws_eip.nat_1c.id

  tags = {
    Name = "handson-1c"
  }
}

resource "aws_eip" "nat_1d" {
  domain = "vpc"

  tags = {
    Name = "handson-natgw-1d"
  }
}

resource "aws_nat_gateway" "nat_1d" {
  subnet_id     = aws_subnet.public_1d.id
  allocation_id = aws_eip.nat_1d.id

  tags = {
    Name = "handson-1d"
  }
}
```

```console
# terraform plan
  :
Plan: 4 to add, 0 to change, 0 to destroy.
  :
# terraform apply
  :
```

## Route Table
最後に、トラフィックを疎通させるための経路設定を行います。  
Internet Gatewayを使用してインターネットへ疎通するためのRoute Table/Routes と NAT Gatewayを経由してインターネットへ疎通するためのRoute Table/Routes を設定します。  

!!! note "Subnetの呼び分け"
    Internet Gatewayと直接的な経路が存在するSubnetを"Public Subnet"と呼び、  
    インターネットへの経路が存在しない・NAT Gatewayを使用してインターネットへ接続しているSubnetを"Private Subnet" と呼びます

![routes](imgs/network-routes-public.png)

まずはInternet GatewayとSubnetの経路を作成しましょう。  
少し多いので解説すると、作成するのは以下の3種類のリソースです。

1. "aws\_route\_table"
    - 経路情報の格納
2. "aws\_route"
    - Route Tableへ経路情報を追加
    - インターネット(0.0.0.0/0)へ接続する際はInternet Gatewayを使用するように設定する
3. "aws\_route\_table\_association"
    - Route TableとSubnetの紐づけ

```ruby
# Route Table
# https://www.terraform.io/docs/providers/aws/r/route_table.html
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson-public"
  }
}

# Route
# https://www.terraform.io/docs/providers/aws/r/route.html
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}

# Association
# https://www.terraform.io/docs/providers/aws/r/route_table_association.html
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1d" {
  subnet_id      = aws_subnet.public_1d.id
  route_table_id = aws_route_table.public.id
}
```

```console
# terraform plan
  :
Plan: 5 to add, 0 to change, 0 to destroy.
  :
# terraform apply
  :
```

![routes](imgs/network-routes-private.png)

NAT GatewayとSubnetの経路を作成しましょう。  
Internet Gateway との違いとしては各AZにNAT Gateway が必要になる点です。

```ruby
# Route Table (Private)
# https://www.terraform.io/docs/providers/aws/r/route_table.html
resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson-private-1a"
  }
}

resource "aws_route_table" "private_1c" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson-private-1c"
  }
}

resource "aws_route_table" "private_1d" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "handson-private-1d"
  }
}

# Route (Private)
# https://www.terraform.io/docs/providers/aws/r/route.html
resource "aws_route" "private_1a" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1a.id
  nat_gateway_id         = aws_nat_gateway.nat_1a.id
}

resource "aws_route" "private_1c" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1c.id
  nat_gateway_id         = aws_nat_gateway.nat_1c.id
}

resource "aws_route" "private_1d" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_1d.id
  nat_gateway_id         = aws_nat_gateway.nat_1d.id
}

# Association (Private)
# https://www.terraform.io/docs/providers/aws/r/route_table_association.html
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private_1c.id
}

resource "aws_route_table_association" "private_1d" {
  subnet_id      = aws_subnet.private_1d.id
  route_table_id = aws_route_table.private_1d.id
}
```

```console
# terraform plan
  :
Plan: 9 to add, 0 to change, 0 to destroy.
  :
# terraform apply
  :
```

経路設定が行えているかWebコンソール上から確認してみましょう。  

確認ポイント

> 1. "handson-" という名前からはじまるRoute Tableが4つあるか
> 2. "handson-public" に3つSubnetが登録されているか
> 3. "handson-public" に登録されているSubnetはPublic Subnetの命名になっているか
> 4. "handson-public" の0.0.0.0への経路はInternet Gatewayを使用しているか
> 5. "handson-private-*" は3つ存在し、それぞれ1つずつSubnetを持っているか
> 6. "handson-private-*" は0.0.0.0への経路はNAT Gatewayを使用しているか

![rtb-list](imgs/rtb-list.png)
[https://ap-northeast-1.console.aws.amazon.com/vpc/home?region=ap-northeast-1#RouteTables:sort=routeTableId](https://ap-northeast-1.console.aws.amazon.com/vpc/home?region=ap-northeast-1#RouteTables:sort=routeTableId)

ここまでで基礎となるネットワークリソースの作成は完了です！  
