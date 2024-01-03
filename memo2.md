# gitでcloneする場合の手順
dockerフォルダでgit cloneする

```sh:
git clone https://github.com/momakas/live-chat-rails.git
```

下記コードを実行していく
```sh:
$ docker-compose build
$ docker-compose run web bundle install
$ docker-compose run web rails db:create
$ docker-compose run web rails db:migrate
$ docker-compose run web rails db:seed
$ docker-compose run frontend npm install --save actioncable
$ docker-compose run frontend npm i --save @fortawesome/vue-fontawesome@prerelease
$ docker-compose run frontend npm i --save @fontawesome/fontawesome-svg-core
$ docker-compose run frontend npm i --save @fortawesome/free-solid-svg-icons
$ docker-compose run frontend npm install date-fns --save

# sh操作
$ docker-compose rub web /bin/sh
```

下記のようなgemのプログラムのバージョンエラーが発生したものがある場合は、Gemfile.lockの中身を削除してから、bundle installし直す
```
Could not find mini_portile2-2.8.1 in any of the sources
Run `bundle install` to install missing gems.
```
frontendは下記でログインできる
 docker-compose run frontend ash

赤坂次郎
jiro-akasaka@xxx.co.jp
1234Pass
$2a$12$nlgjnFwpp8vF3FqLCU.U8ufgArnbKhrrWaT0xWItQ2hhpG5Tvo9wi

赤坂三郎
saburo-akasaka@xxx.co.jp
1235Pass

赤坂四郎
shiro-akasaka@xxx.co.jp
1236Pass

赤坂五郎
goro-akasaka@xxx.co.jp
1235Pass
