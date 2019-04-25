## 概要
このハンズオンではLaravelをECS上で動かします。  
その前に今回立ち上げるLaravelをdocker-composeを使用してローカル環境を立ち上げてみましょう。


## 準備
先程作成したディレクトリへ入り、Laravelプロジェクトの初期化を行います。

```console
$ cd ~/Desktop/laravel
$ docker run -v `pwd`:/app -w /app composer create-project --prefer-dist laravel/laravel laravel
$ ls
laravel terraform
```

## Dockerコンポーネントの準備
docker-composeを立ち上げるために、Laravelプロジェクトのdockerizeをします。

まずはlaravelディレクトリが存在するか確認しましょう
```console
$ cd laravel
$ ls
app            bootstrap      composer.lock  database       phpunit.xml    readme.md      routes         storage        vendor
artisan        composer.json  config         package.json   public         resources      server.php     tests          webpack.mix.js
```

Laravelを起動するために今回はnginxも使用します。  
nginxとLaravelのDocker用ファイルを用意していきましょう

### Laravel
まずはLaravelの設定から行いましょう。

```console
$ vi Dockerfile
```
```Dockerfile
FROM php:7.2-fpm-alpine

ARG UID=991
ARG UNAME=www
ARG GID=991
ARG GNAME=www

ENV WORKDIR=/var/www/html
WORKDIR $WORKDIR

COPY ./docker/php/php.ini /usr/local/etc/php
COPY composer.json composer.lock ${WORKDIR}/

RUN set -x \
    && apk add --no-cache git php7-zlib zlib-dev \
    && docker-php-ext-install pdo_mysql zip \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer install --no-autoloader --no-progress --no-dev

COPY . .

RUN set -x \
    && composer install --no-progress --no-dev \
    && php artisan config:clear \
    && addgroup ${GNAME} -g ${GID} \
    && adduser -D -G ${GNAME} -u ${UID} ${UNAME} \
    && chown -R ${UNAME}:${GNAME} ${WORKDIR} \
    && mv /root/.composer /home/${UNAME}/ \
    && chown -R ${UNAME}:${GNAME} /home/${UNAME}

USER ${UNAME}
```

PHPを使用する場合はPHPの設定ファイル `php.ini` が欲しいため、その作成を行います。
```console
$ mkdir -p docker/php/php.ini
$ vi docker/php/php.ini
```
```
[php]
expose_php = Off
default_charset = "UTF-8"
max_execution_time = 30
memory_limit = 128M
file_uploads = On
upload_max_filesize = 5M
post_max_size = 5M
```

laravel自体の設定ファイルを記載します。  
ハンズオンの簡易化のためにdocker-composeで `.env` ではなく `.env.example` から環境変数の設定を読み込みます。プロダクションでは厳密に管理したほうが良いでしょう。

環境変数から不要な設定を外し、ローカルでLaravelからMySQLへの接続設定をします。

```console
$ vi .env.example
```
```
APP_NAME=handson
APP_ENV=local
APP_KEY=
APP_KEY=base64:p5Fu8gRUOuPUXzY3VcxpnYsUR9f2h8nTSm5JlYkzPTM=
APP_DEBUG=true
APP_URL=http://localhost

LOG_CHANNEL=stderr

DB_CONNECTION=mysql
DB_HOST=mysql
DB_DATABASE=app
DB_USERNAME=root
DB_PASSWORD=
```

ここまででLaravelの設定は終わりです。

### nginx
従来のホスト上で環境構築をする場合nginxを立てるのは煩わしいだけでしたが、dockerのおかげで簡単に立ち上げることができるようになりました。  
プロダクション環境との際を小さくするためにも、ローカルでもnginxを立ててしまいましょう。

nginxにきたトラフィックをphpへ渡す設定を書きます。  
```console
$ mkdir docker/nginx
$ vi docker/nginx/default.conf.template
```
```nginx
server {
    listen 80;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    root /var/www/html/public/;
    charset     utf-8;

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    location / {
        try_files $uri /index.php?$query_string;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_pass            ${PHP_HOST}:9000;
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        fastcgi_index           index.php;
        fastcgi_param           SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        fastcgi_param           PATH_INFO        $fastcgi_path_info;
        fastcgi_param           REQUEST_FILENAME $request_filename;
        include                 fastcgi_params;
    }
}
```

nginx用Dockerfileの記載を行います。

```Dockerfile
FROM nginx:1.15-alpine

COPY public /var/www/html/public
COPY docker/nginx/default.conf.template /etc/nginx/conf.d/default.conf.template

ENV PHP_HOST=127.0.0.1

EXPOSE 80

CMD /bin/sh -c 'sed "s/\${PHP_HOST}/${PHP_HOST}/" /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g "daemon off;"'
```


nginxは1点ポイントがあります。  
ネットワークドライバによってDNS経由からローカルホスト経由か、ネットワークが異なるため、 `default.conf.template` で `${PHP_HOST}` で一旦変数(?)にします。
```
        fastcgi_pass            ${PHP_HOST}:9000;
```

そしてDocker起動時に `sed` で書き換えます。  
デフォルトはDockerfile内の `ENV PHP_HOST=127.0.0.1` にて `127.0.0.1` を指定してローカルホストにしています。
```
CMD /bin/sh -c 'sed "s/\${PHP_HOST}/${PHP_HOST}/" /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g "daemon off;"'
```

数が多い場合 `envsubst` コマンドでも良いのですが、1箇所書き換えるだけならシンプルに `sed` の方が分かりやすいでしょう。

ここまででdockerの設定は完了です。


## docker-compose

先ほど作成したDockerfileと各種設定を読み込むdocker-composeの設定を記載します。
```console
$ vi docker-compose.yaml
```
```yaml
version: '3.7'

services:
  nginx:
    build:
      context: .
      dockerfile: docker/nginx/Dockerfile
    volumes:
      - ./public:/var/www/html/public:ro
    ports:
      - 8001:80
    environment:
      PHP_HOST: app

  app:
    build: .
    env_file:
      - .env.example
    volumes:
      - .:/var/www/html:cached

  mysql:
    image: mysql:5.7
    volumes:
      - ./mysql:/var/lib/mysql:delegated
    command: mysqld --character-set-server=utf8mb4 --collation-server=utf8mb4_general_ci
    environment:
      MYSQL_ALLOW_EMPTY_PASSWORD: 'yes'
      MYSQL_DATABASE: 'app'
    ports:
      - 3306
```

記述しおわったら起動し、動作確認をします。
```
$ docker-compose up
```

[http://localhost:8001](http://localhost:8001)

Laravelのウェルカムページが表示されれば成功です！

## MySQLを使用する
ここからはLaravelとMySQLを連携してみましょう。

### migrateの実行
起動しているdocker-composeをそのままに、別のターミナルを開いて操作します。

まずはmigrateの実行を行います。  
既に起動しているDockerコンテナの中で `php` コマンドを打ってmigrateを行います。

```
$ cd /path/to/introduction-terraform-example/laravel
$ docker-compose exec app php artisan migrate
```

## APIの動作確認
まずは `/api/books` のパスにアクセスして、何も帰ってこないことを確認します。  

```
$ curl localhost:8001/api/books
[]
```

何回かPOSTリクエストを送って、データを増やしてみます。  
```
$ curl -X POST localhost:8001/api/books
{
  "title": "Ramiro Bernhard",
  "updated_at": "2019-03-20 04:59:05",
  "created_at": "2019-03-20 04:59:05",
  "id": 1
}
$ curl -X POST localhost:8001/api/books
{
  "title": "Ramiro Bernhard",
  "updated_at": "2019-03-20 04:59:05",
  "created_at": "2019-03-20 04:59:05",
  "id": 2
}
   :
```

最後に `/api/books` へGETリクエストを送り、MySQLへデータが格納されていることを確認します。

```
$ curl localhost:8001/api/books
[
  {
    "id": 1,
    "title": "Ramiro Bernhard",
    "created_at": "2019-03-20 04:59:05",
    "updated_at": "2019-03-20 04:59:05"
  },
  {
    "id": 2,
    "title": "Mr. Ford Nitzsche",
    "created_at": "2019-03-20 05:00:36",
    "updated_at": "2019-03-20 05:00:36"
  }
]
```

## MySQLの中に入ってみる
Dockerコンテナ上で動かしているMySQLへログインしてみます。  

```
$ docker-compose exec mysql mysql
Your MySQL connection id is 8
Server version: 5.7.25 MySQL Community Server (GPL)

Copyright (c) 2000, 2019, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql>
```

MySQLの公式Docker Image は環境変数で定義した `app` というデータベースが作成されます。  
MySQLコンテナの中に入り、 `app` データベースのテーブルを一覧してみましょう。

```
mysql> use mysql
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show tables;
+-----------------+
| Tables_in_app   |
+-----------------+
| books           |
| migrations      |
| password_resets |
| users           |
+-----------------+
4 rows in set (0.00 sec)
```
