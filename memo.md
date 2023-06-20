# Docker + Rails6 + React for Mac

## 参考ページ

- [AWS FargateでRuby on Railsを動かしてみる - Qiita](https://qiita.com/riywo/items/3874fe1a9f11658b8396)

- [AWS公式ドキュメント：Amazon ECS を使用するようにセットアップする](https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/get-set-up-for-amazon-ecs.html)

- [【保存版】AWS RDSを起動し、実際にデータベース・テーブルを操作してみよう！](https://note.com/standenglish/n/n8fce48f8dbfa)

- [猫でもわかるHotwire入門 Turbo編](https://zenn.dev/shita1112/books/cat-hotwire-turbo)

- [Docker × Rails6 API × React環境for Mac[vol3]](https://usconsort.com/docker-env-vol3/)

- [armとintelのdocker-compose共通化へ向けて(Ruby on Rails編)￼](https://matsu.teraren.com/blog/2022/04/26/docker-m1-arm-glibc-error-on-nokogiri/)

- [【MySQL】Unknown MySQL server host 'db' (-2)の対処法【Docker】](https://qiita.com/SyoInoue/items/2ed5b3017c517920ec09)

- [Docker + Rails6 + React + TypeScript の環境構築](https://qiita.com/yuki-endo/items/a99cdde478c2a2d057d9)

- [docker images を全削除する](https://qiita.com/fist0/items/2fb1c7f894b5bdff79f4)

- [M1macbookpro+dockerでRails開発環境構築](https://norix.tokyo/environment/443/)

- [【ポートフォリオをECSで！】Rails×NginxアプリをFargateにデプロイするまでを丁寧に説明してみた(VPC作成〜CircleCIによる自動デプロイまで) 前編](https://qiita.com/maru401/items/8e7d32a8baded045adb2)

- [Alpine Linuxのパッケージ管理システムapkについて理解を深める](https://blog.kasei-san.com/entry/2020/08/25/084430)

- [Makefileでmake時に 「*** missing separator. Stop.」 と出たときの対処法](https://kakts-tec.hatenablog.com/entry/2016/12/18/225353)

## 事前準備

下記を予めインストールしておく

- AWS CLI
- ESC CLI
- Docker CLI（Compose含む）

## ファイルの用意

下記ファイルを作成する。

<details><summary>Makefile</summary>

```Makefile
new:
	echo "$$_gemfile" > Gemfile
	touch Gemfile.lock
	docker-compose run web rails new . --force --database=mysql --skip-bundle --skip-javascript
	# chown→ファイルの所有者を変更、-R→ディレクトリ内の所有者も変更、.→任意のファイル
	# chown a:c b→ファイルbの所有者をユーザa（グループ権限c）に変更
	sudo chown -R $$USER:$$USER .
	echo "$$_database_yml" > config/database.yml
	docker-compose build
	docker-compose run web rails generate controller welcome index
	docker-compose run web sh -c 'sleep 20 && rake db:create'
	sudo chown -R $$USER:$$USER .

run:
	docker-compose up --build

define _gemfile
source 'https://rubygems.org'
gem 'rails'
endef
export _gemfile

define _database_yml
default: &default
  adapter: mysql2
  encoding: utf8
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
  password: password
  host: db

development:
  <<: *default
  database: myapp_development

test:
  <<: *default
  database: myapp_test

production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
endef
export _database_yml

push:
	docker-compose run web rake assets:precompile
	sudo chown -R $$USER:$$USER .
	docker-compose build
	ecs-cli push $(APP_NAME) --region $(REGION)

export IMAGE  = $(shell aws ecr describe-repositories --region $(REGION) --repository-names $(APP_NAME) --query 'repositories[0].repositoryUri' --output text)
export DIGEST = $(shell aws ecr batch-get-image --region $(REGION) --repository-name $(APP_NAME) --image-ids imageTag=latest --query 'images[0].imageId.imageDigest' --output text)

migrate:
	ecs-cli compose -f migrate-compose.yml --project-name $(APP_NAME)-migrate up --cluster $(CLUSTER) --region $(REGION)

export IMAGE = ${shell aws ecr describe-repositories --region ${REGION} --repository-names ${APP_NAME} --query 'repositories[0].repositoryUri' --output text)
export DIGEST = $(shell aws ecr batch-get-image --region ${REGION} --repository-name ${APP_NAME} --image-ids imageTag=latest --query 'images[0].imageId.imageDigest' --output text)

deploy:
	ecs-cli compose -f app-compose -f app-compose.yml --project-name up --cluster ${CLUSTER} --region ${REGION}

```

</details>

<details><summary>docker-compose.yml</summary>

```yml: docker-compose.yml
version: '2'
services:
  db:
    image: mysql
    platform: linux/x86_64
    environment:
      MYSQL_ROOT_PASSWORD: password
      # MYSQL_ALLOW_EMPTY_PASSWORD: 'yes'
  web:
    image: ${APP_NAME}
    build: .
    volumes:
      - .:/myapp
    ports:
      - "8080:3000"
    environment:
      PORT: "3000"
    depends_on:
      - db
```

</details>

<details><summary>Dockerfile</summary>
  - Alipine Linuxベースのものを利用しているとイメージサイズは100MB以下にできる

```Dockerfile
FROM --platform=linux/amd64 ruby:3.1.0-alpine
# M1Macは上記を記述する必要あり
# FROM ruby:2.4-alpine

# RUN apk add -U mariadb-client-libs tzdata
RUN apk add -U mariadb-dev tzdata
RUN mkdir /myapp
WORKDIR /myapp
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock
RUN apk add -U build-base ruby-dev mariadb-dev --virtual .build-deps \
  && apk add bash git \
  && bundle install -j 4 \
  && gem sources --clear-all \
  && apk del .build-deps \
  && rm -rf /var/cache/apk/* \
            /root/.gem/ruby/3.1.0/cache/*.gem
COPY . /myapp
CMD exec bundle exec rails s -p ${PORT} -b '0.0.0.0'
```

</details>

## Makefileの実行

```bash
APP_NAME=rails make new
```

## 起動

ローカルで起動してみる

```bash
APP_NAME=rails make run
```

## Amazon ECRにイメージをpushする

Makefileを使用する

```bash
APP_NAME=rails REGION=us-east-1 make push
```

## 本番環境の準備をする

- Default VPCのDefault Subnet、Default Security GroupのID
- HTTPでアクセスできるSecurity Group
  - Default VPC上に作成
- Amazon CludWatch LogsのLog Group - 例：`/ecs/rails`
- Amazon RDS for MySQLのインスタンス
  - Security GroupはDefault Security Groupを指定
- Amazon ECSのクラス - 例： `rails-cluster`
  - Default VPCを利用するので、VPCの作成は不要です

### 手順

<details><summary>IAM Identity Center設定</summary>

- 参考[Getting started](https://docs.aws.amazon.com/singlesignon/latest/userguide/getting-started.html)

サインインするユーザを管理できるようにする。

- AWSコンソールにサインインする
- IAM Identity Centerコンソールを開く
- [IAM Identity Center](https://console.aws.amazon.com/singlesignon)
- IAM IDセンターを有効にする。
- AWS組織を作成します。
- 画面右上のアカウント名を選択し、組織から確認可能。

</details>

<details><summary>Amazon VPCを作成する</summary>

- 参考[Amazon ECS を使用するようにセットアップする - 仮想プライベートクラウドを作成する](https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/get-set-up-for-amazon-ecs.html)

Amazon Virtual Private Cloud (Amazon VPC) を使用すると、定義した仮想ネットワーク内で AWS リソースを起動できます。コンテナインスタンスは、VPC で起動することを強くお勧めします。

- AWSコンソールにサインインする
- 画面右上のリージョンをバージニア北部に切り替える。
- 検索窓にVPCで検索し、VPCを選択
- デフォルトのVPCを作成する。

|オプション|値|
| ---- | ---- |
|作成するためのリソース|VPC のみ|
|名前|オプションで、VPC の名前を指定します。|
|IPv4 CIDR ブロック|IPv4 CIDR 手動入力<BR><BR>CIDR ブロックサイズは /16 から /28 の間である必要があります。|
|IPv6 CIDR ブロック|IPv6 CIDR ブロックなし|
|テナンシー|デフォルト|

- Default Subnet、Default Security GroupのIDが作成されるのでメモしておく。

</details>

<details><summary>セキュリティグループの作成</summary>

- 参考[Amazon ECS を使用するようにセットアップする - セキュリティグループの作成](https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/get-set-up-for-amazon-ecs.html)

コンテナインスタンスのファイアウォール。

- AWSコンソールにサインインする
- 画面右上のリージョンをバージニア北部に切り替える。
- [Work with security groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/working-with-security-groups.html#creating-security-group)を参考に作成する
- デフォルトのセキュリティグループを作成する。
  - 検索窓にVPCで検索し、VPCを選択
  - ナビゲーションペインで、セキュリティグループを選択します。
  - セキュリティグループを作成を選択する。
  - セキュリティグループの説明的な名前と簡単な説明を入力
  - デフォルトVPCを選択する
  - セキュリティグループを作成を選ぶ
- HTTPアクセスできるSecurity Groupを作成する
- デフォルトのセキュリティグループ同様に作成。
- 下記の通りにインバウンドルールの作成を行う

|オプション|値|
| ---- | ---- |
|HTTP ルール|[Type]: HTTP<BR><BR>ソース: 任意の場所 (0.0.0.0/0)|
|HTTPS ルール|タイプ: HTTPS<BR><BR>ソース: 任意の場所 (0.0.0.0/0)|
|SSH ルール|タイプ: SSH<BR><BR>ソース: [Custom] で、コンピュータまたはネットワークのパブリック IP アドレス（自宅のGlobal Ipアドレス）を CIDR 表記で指定します。CIDR 表記で個々の IP アドレスを指定するには、ルーティングプレフィックスを追加します。/32たとえば、IP アドレスが 203.0.113.25 の場合は、203.0.113.25/32 を指定します。会社が特定の範囲からアドレスを割り当てている場合、 203.0.113.0/24 などの範囲全体を指定します。<BR><BR>重要<BR>セキュリティ上の理由で、すべての IP アドレス (0.0.0.0/0) からインスタンスへの SSH アクセスを許可することはお勧めしません。ただし、それがテスト目的で短期間の場合は例外です。|

- 作成した２つのセキュリティグループのIDをメモしておく。

</details>

<details><summary>AWS RDSの作成</summary>

- 画面右上のリージョンをバージニア北部に切り替える。
- 可用性と耐久性はマルチAZ構成が望ましい
- パブリックアクセスはなし
- VPC、サブネット、セキュリティグループはデフォルトでOK

</details>

<details><summary>ロググループの作成</summary>

- 画面右上のリージョンをバージニア北部に切り替える。
- CloudWatch→ロググループから「ロググループの作成」で作成
- ロググループ名の例：/ecs/rails

</details>

<details><summary>Clusterの作成</summary>

- 画面右上のリージョンをバージニア北部に切り替える。
- 検索窓からecsで検索。クラスタを選択し、「クラスターの作成」から作成。
- クラスタ名例：rails-cluster
- VPC、サブネットはデフォルトでOK
- タスク定義は作成不要。Makefileで作成する。

</details>

### IDE側準備

次に、ECS CLIの設定である`ecs-params.yml`を作成します。

<details><summary>ecs-params.yml</summary>

```yml: ecs-params.yml
version: 1
task_definition:
  ecs_network_mode: awsvpc
  task_execution_role: ecsTaskExecutionRole
  task_size:
    cpu_limit: 256
    mem_limit: 512
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
      - subnet-07e01f6790b483495
      - subnet-04ee8fdb30762dee4
      - subnet-0fb7421e5416883ab
      security_groups:
      - sg-029e83f16cdd260df
      - sgr-0a486114c59599353
      assign_public_ip: ENABLED
```

</details>

また、本番環境に適応する環境変数を`.env.production`にまとめておきます。

<details><summary>.env.production</summary>

```.env.production
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=1
RAILS_SERVE_STATIC_FILES=1
SECRET_KEY_BASE=mysecretkey
DATABASE_URL=mysql2://username:password@rds.hostname/dbname
```

- SECRET_KEY_BASEは右上のアカウント名→セキュリティ認証情報→セキュリティ認証情報タブのアクセスキーから取得。
- DATABASE_URL=mysql2://root:h6y9acZnA!@database-1.cqyhz0w4qhwx.us-east-1.rds.amazonaws.com/rails_database
- rds.hostnameは「接続とセキュリティ」タブのエンドポイント
- dbnameは「設定」タブのDB名から取得

</details>

## Pushしたイメージを使って`rake db:migrate`をFargateで実行する

Makefileから管理タスクである`rake db:migrate`を実行して、MySQL上にスキーマを作成します。
`ecs-cli`ではRunTask時のCommandの上書きができないので、migrate用のComposeファイル`migrate-compose.yml`を作成します。

<details><summary>migrate-compose.yml</summary>

```yml: migrate-compose.yml
version: '2'
services:
  web:
    image: ${IMAGE}@${DIGEST}
    command: ["rake", "db:migrate"]
    env_file: .env.production
    logging:
      driver: awslogs
      options:
        awslogs-region: ${REGION}
        awslogs-group: ${LOG_GROUP}
        awslogs-stream-prefix: ecs
```

</details>

Makefileを実行する

```bash
APP_NAME=rails REGION=us-east-1 LOG_GROUP=/ecs/rails CLUSTER=rails-cluster make migrate
```

実行結果のログを見てみます。先ほどの出力の`container=rails-cluster/271f82f9e2ff4ca4825199852a269e2c/web`の前半部分`271f82f9e2ff4ca4825199852a269e2c`がタスクIDになります。

```bash
ecs-cli logs --region us-east-1 --cluster rails-cluster --task-id 5685060e72ed44578edbe40a5e8ce00e
```

## 同じイメージを使ってRails ServerをFargateにデプロイする

最後にRails Serverを立ち上げる。`app-compose.yml`を準備する。`migrate-compose.yml`と大差ないです。

<details><summary>app-compose.yml</summary>

```yml:app-compose.yml
version: '2'
services:
  web:
    image: ${IMAGE}@${DIGEST}
    ports:
    - "80:80"
    env_file: .env.production
    environment:
      PORT: "80"
    logging:
      diver: awslogs
      options:
        awslogs-region: ${REGION}
        awslogs-group: ${LOG_GROUP}
        awslogs-stream-prefix: ecs
```

</details>

Makefile実行する

```bash
APP_NAME=rails REGION=us-east-1 LOG_GROUP=/ecs/rails CLUSTER=rails-cluster make deploy
```

IPアドレスを確認してブラウザでアクセスしてみます。

```bash
% ecs-cli ps --region us-east-1 --cluster rails-cluster
Name                                      State    Ports                     TaskDefinition
eadcb254-36b0-472a-93af-a40038d80a6c/web  RUNNING  34.202.233.73:80->80/tcp  rails-app:4
```

ブラウザに`34.202.233.73`でアクセスする。
`RAILS_ENV=production`だとWelcomeページは設定しないと出ないので、表示できないのは期待通りです。`/welcome/index`にアクセスしてみると正しくレンダリングされていることがわかります。
`34.202.233.73/welcome/index`にアクセスすると、Welcomeページが表示される。
最も大事なことは、EC2インスタンスのことを考えたことは一度もなく、あくまでタスクとそれに紐づくリソースについてのみ考えればよかったということです。

## 料金

- ECR
  - 新しい Amazon ECR のお客様には、AWS 無料利用枠の一部として、プライベートリポジトリ用に 1 年間月々 500 MB のストレージをご利用いただけます。
  - 新規のお客様も既存のお客様も、パブリックリポジトリ用に 50 GB/月のストレージを常時無料でご利用いただけます。匿名で (AWS アカウントを使用せずに) 毎月 500 GB のデータを無料でパブリックリポジトリからインターネットに転送できます。AWS アカウントにサインアップするか、既存の AWS アカウントで Amazon ECR に認証すると、毎月 5 TB のデータをパブリックリポジトリからインターネットに無料で転送できます。また、パブリックリポジトリから任意の AWS リージョンの AWS コンピューティングリソースにデータを転送する際には、コスト無しで無制限の帯域幅を得ることができます。
  - 無料利用枠はすべてのリージョンで毎月計算され、お客様の請求額に自動的に適用されます。なお、無料利用枠の翌月への繰り越しはできません。
- クラスタ
  - AWS Fargate 起動タイプモデル
    - AWS Fargate では、コンテナ化されたアプリケーションに必要な vCPU とメモリリソースに対する料金が発生します。vCPU とメモリリソースは、コンテナイメージを取得した時点から Amazon ECS タスク* が終了するまでを対象として計算され、最も近い秒に切り上げられます。1 分の最低料金が適用されます。
    - タスク定義削除しておけば請求されない？

## memo

``` bash
% docker-compose up
```

``` bash
docker-compose run api rails g scaffold Dog name:string age:integer
docker-compose run api rails g scaffold Chick name:string age:integer
docker-compose run api rails g scaffold Hedgehog name:string age:integer
docker-compose run api rails g scaffold Owl name:string age:integer
docker-compose run api rails db:migrate
docker-compose run api rails db:seed
```

- その他

```bash
# コンテナ停止（control cでも可）
$ docker-compose down
# イメージ全削除
docker images -aq | xargs docker rmi
# コンテナ内でbash実行
docker-compose run api /bin/bash
```

httpsで接続させたい！！！！

- ユーザリスト
```txt:
monaka
monaka@xxx.co.jp
Password05

Momoko
momoko2@test.com
123456
```