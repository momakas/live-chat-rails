# gitでcloneする場合の手順
dockerフォルダでgit cloneする

```sh:
git clone https://github.com/momakas/live-chat-rails.git
```

下記コードを実行していく
```sh:
$ docker-compose build
$ docker-compose run web bundle install
$ docker-compose run web db:create
$ docker-compose run web db:migrate
```

下記のようなgemのプログラムのバージョンエラーが発生したものがある場合は、Gemfile.lockの中身を削除してから、bundle installし直す
```
Could not find mini_portile2-2.8.1 in any of the sources
Run `bundle install` to install missing gems.
```
