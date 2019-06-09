# HttpServer

システム開発プロジェクト基礎第一の課題

TODO管理サービス用のHTTPサーバ

## 概要
[Elixirのインストール](https://elixir-lang.org/install.html)

[PostgreSQLのインストール](https://www.postgresql.org/download/)

HttpServerの実行
```
git clone https://github.com/Skroig0010/HttpServer.git
cd HttpServer
mix deps.get
pg_ctl start -l logfile
mix ecto.create
mix ecto.migrate
mix run --no-halt
```

### イベント登録 API request
POST /api/v1/event

{"deadline": "2019-06-11T14:00:00+09:00", "title": "レポート提出", "memo": ""}

### イベント全取得 API request
GET /api/v1/event

### イベント1件取得 API request
GET /api/v1/event/${id}

### イベント全削除 API request
DELETE /api/v1/event/

### イベント1件削除 API request
DELETE /api/v1/event/${id}

### イベント範囲指定取得 API request
GET /api/v1/event/?from=2019-06-10T14:00:00+09:00&to=2020-06-10T14:00:00+09:00


## 構成
Plug: HTTPサーバーライブラリ

Ecto: DBラッパー


lib/http\_server/router.ex: ルーターの実装

lib/http\_server/todo\_event: スキーマとvalidationの定義


test/http\_server/router\_test.exs: 各種テスト実装
