# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :http_server, HttpServer.Repo,
adapter: Ecto.Adapters.Postgres,
database: "http_server_repo",
username: "main",
password: "",
hostname: "localhost"


config :http_server, cowboy_port: 8080
config :http_server, ecto_repos: [HttpServer.Repo]
