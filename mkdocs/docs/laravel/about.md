![architecture](imgs/architecture.png)

ここまではTerraformに慣れることを目的にハンズオンを行いました。  
ここからはPHPのフレームワーク "Laravel" を使用し、実際にECSとRDSを使用して構築します。

サンプルコードは以下にあるので、つまったら見てください。
```console
$ git clone https://github.com/y-ohgi/introduction-terraform-example
```

## 準備
[シンタックスの活用](../../handson/syntax) で例に上げたコードを追加する形で勧めます。  
作業用のディレクトリを作成し、コピーするところから初めましょう。

```console
$ cd ~/Desktop/
$ git clone https://github.com/y-ohgi/introduction-terraform
$ mkdir laravel
$ cp -R introduction-terraform/handson/syntax laravel/terraform
$ cd laravel
$ ls
terraform
```

```console
$ cd terraform
$ vi main.tf # variableで定義しているドメイン名の修正
$ terraform init
$ terraform apply
```

独自ドメインでnginxの画面が見れれば成功です。  
今回はnginxを使用しないので、コメントアウトしましょう。
