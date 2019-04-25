
この章では今まで使用したTerraformのシンタックスについて学んでいきます。  
今まで使用してきたブロック `prodivder` , `resource` , `variable` , `data` のふりかえりと、新しく `terraform` , `output` , `module` , `locals` について学んでいきます。

## provider
AWS/GCP/Azureのようなクラウド、オンプレ、SaaSなど、どのインフラを使うかの宣言を行います。  

```ruby
provider "aws" {
  region = "ap-northeast-1"
}
```

## resource
インフラ上へ作成するリソースを定義します。  
基本的にTerraformはこの `resource` ブロックを [リファレンス](https://www.terraform.io/docs/providers/aws/index.html) を読みながら書いていきます。

```ruby
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

## variable
変数の定義を行います。  
共通で使用したり環境毎に分けて定義したい値をここで宣言します。

```ruby
variable "name" {
  description = "リソースに共通して付与する命名"
  type        = "string"
  default     = "handson"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_subnet" "public_1a" {
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "${var.name}-public-1a"
  }
}
```

## data
既存のリソースから情報を取り込みます。  
例えば手動で作成したドメインをコードで管理したり、別のTerraformで管理しているリソースを取り込む際に使用します。

```ruby
variable "vpc_id" {
  description = "取り込むVPCのID"
  type        = "string"
  default     = "vpc-083474491091d1639""
}

data "aws_vpc" "main" {
  id = "${var.vpc_id}"
}

resource "aws_subnet" "public_1a" {
  vpc_id = "${data.aws_vpc.main.id}"

  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.1.0/24"
}
```

## terraform
terraformブロックを定義することでTerraformが現在管理しているリソース情報をリモートで管理することができます。  
これによりバックアップや多人数開発が可能になるため、基本的にterraformブロックは使用することが好ましいです。  
AWSであればS3を、GCPであればGCSを使用すると良いでしょう。また、terraformブロックで指定するS3(GCS)は先に作成する必要があります。

```ruby
terraform {
  backend "s3" {
    bucket = "<YOUR S3 BUCKET>"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}
```

## module
Terraformコードを分割するための機能です。  
例えばネットワーク・ロードバランサ・コンテナなどの単位で分割したり、他人が公開しているTerraformのコードを読み込むことが可能です。

```ruby
# ./main.tf

module "network" {
  source = "./network"
}
```

```ruby
# ./network/main.tf

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_1a" {
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.1.0/24"
}
```

## output
module内のリソースの情報を、module外へ公開するために使用します。  

```ruby
# ./main.tf

module "network" {
  source = "./network"
}

resource "aws_security_group" "main" {
  name        = "handson"
  description = "handson"

  # moduleを参照する
  vpc_id      = "${module.network.vpc_id}"
}
```

```ruby
# ./network/main.tf

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

output "vpc_id" {
  value       = "${module.vpc.vpc_id}"
}
```

## locals
variableブロックと同じく、変数の宣言を行います。  
違いとしては2点「スコープ」と「関数の使用が可能」な点です。

variableを定義するとスコープがグローバルになることに対し、localsはスコープがmodule内だけになります。


```ruby
locals {
  name = "myapp"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "${local.name}"
  }
}
```

## count
繰り返し実行を行う際に使用します。  
例えばSubnetのようなほぼ同じプロパティを定義して複数作成するようなリソースだとコード数の削減と可読性の向上へ役立ちます。

```ruby
provider "aws" {
  region = "ap-northeast-1"
}

variable "azs" {
  description = "サブネットを配置するAZ。regionと対応させる必要あり"
  default     = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

variable "subnet_cidrs" {
  description = "作成するサブネットCIDR一覧"
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  # length関数でsubnet_cidrsの数を取得し、その数ぶん繰り返し実行する
  count = "${length(var.subnet_cidrs)}"

  vpc_id = "${aws_vpc.main.id}"

  # 現在の実行回数をcount.indexで取得でき、それをインデックスとして配列から値を取得する
  availability_zone = "${var.azs[count.index]}"
  cidr_block        = "${var.subnet_cidrs[count.index]}"
}
```

## 三項演算子
条件分岐は三項演算子として記述することが可能です。  
1環境しか作成しない場合は基本使用しませんが、複数環境作成する場合環境依存になってしまう箇所が発生します。その環境によって異なる値を振り分けるために使用することが多いです。

```ruby
variable "env" {
  description = "環境名"
  default     = "dev"
}

locals {
  cidr = "${ env == "prd" ? "10.0.0.0/16" : "172.16.0.0/16" }"
}

resource "aws_vpc" "main" {
  cidr_block = "${locals.cidr}"
}
```

## depends_on
各リソースの依存関係を定義し、リソースの作成順番を制御します。  
基本的にTerraformが依存関係と作成順は解決してくれますが、稀に作成順の定義が必要になるケースがあるので覚えておくと良いでしょう。

## シンタックスの活用
![aws](../../handson/imgs/aws.png)

[ハンズオン](../../handson/about/) で定義したコードは非常長く、可読性が悪くなっています。  
この章で紹介したシンタックスを使用するとどの様になるか、サンプルコードを記述しました。

[https://github.com/y-ohgi/introduction-terraform/tree/master/handson/syntax](https://github.com/y-ohgi/introduction-terraform/tree/master/handson/syntax)

この後の章はこのサンプルコードをもとに構築を進めます。
