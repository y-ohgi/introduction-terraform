## この章の目標
この章ではLaravelを立ち上げるためにDockerの準備を行います。

## やること
- ECRの作成
- dockerのビルド
    - ホストマシンでやる的なこと
- ECRへのpush
    - aws cli のログイン

### ECRの作成
Dockerの保管にはAWSのDockerマネージドサービスである "Elastic Container Registry" を使用します。  
イメージとしてはDockerHubのAWS版のようなものです。

前提としてはECRをTerraformで管理しません。  
Terraformは1環境(STG/PRD毎)の定義のために使用しますが、Dockerイメージは一般的に複数環境にまたがって共通のものを使用します。  
IaCは非常に便利ですが、100%コード化するべきなのかは適宜判断しましょう。

ECRはAWSコマンドから作成します。  

`nginx` と `app` (Laravel)'の2つのリポジトリを作成します。

```console
$ aws ecr create-repository --repository-name nginx
$ aws ecr create-repository --repository-name app
```

作成されたかの確認します。

```console
$ aws ecr describe-repositories --query 'repositories[].repositoryName'
[
    "nginx",
    "app"
]
```

### Dockerのビルド
ハンズオンリポジトリへチェックアウト
```console
$ cd ~/Desktop/laravel/laravel
```

nginxのビルド

```console
$ export ECR_URI_NGINX=$(aws ecr describe-repositories --repository-names nginx --query 'repositories[0].repositoryUri' --output text)
$ docker build -t ${ECR_URI_NGINX} -f docker/nginx/Dockerfile .
```

Laravelのビルド

```console
$ export ECR_URI_APP=$(aws ecr describe-repositories --repository-names app --query 'repositories[0].repositoryUri' --output text)
$ docker build -t ${ECR_URI_APP} .
```

### ECRへのpush
ECRへログインします。  

```console
$ aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com
```

nginxのpush
```console
$ docker push ${ECR_URI_NGINX}
```

Laravelのpush
```console
$ docker push ${ECR_URI_APP}
```
