## About
Terraformについてハンズオン形式で学ぶドキュメントです。  
なるべく本番環境に近い環境をTerraformで構築し、「実務ですばやくTerraformを記述/導入できるようになる」ことが目的です。

## Version
- Docker
    - 18.09.3
- docker-compose
    - 1.23.2
- Terraform
    - 0.11.13

## 必要な環境
- AWSアカウント
    - [クラウドならアマゾン ウェブ サービス 【AWS 公式】](https://aws.amazon.com/jp/)
- Docker for Mac/Windows
    - [Docker CE — Docker-docs-ja 17.06.Beta ドキュメント](http://docs.docker.jp/engine/installation/docker-ce.html)
    - Mac: `$ brew cask install docker`
- AWS CLI
    - [AWS Command Line Interface をインストールする - AWS Command Line Interface](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-chap-install.html)
    - Mac: `$ brew install awscli`
    - Windows: `> choco install awscli`
- ドメイン
    - https化を行うため、Route53上でドメインを管理している必要があります。
