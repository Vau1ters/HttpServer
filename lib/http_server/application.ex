defmodule HttpServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Plug.Cowboy, scheme: :http, plug: HttpServer.Router, options: [port: cowboy_port()]}
    ]

    opts = [strategy: :one_for_one, name: HttpServer.Supervisor]

    Logger.info("Starting application...");
    Supervisor.start_link(children, opts)
  end

  defp cowboy_port, do: Application.get_env(:http_server, :cowboy_port, 8080)
end
