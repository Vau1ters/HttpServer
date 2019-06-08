defmodule HttpServer.Router do
  use Plug.Router
  alias HttpServer.Plug.VerifyRequest

  plug Plug.Parsers, parsers: [:urlencoded, :json],
                     pass: ["application/json"],
                     json_decoder: Jason
  plug :match
  plug :dispatch

  @success %{ status: "success", message: "registered", id: 0 }
  @failure %{ status: "failure", message: "invalid date format" }

  @data %{
    events: [
      %{id: 0, deadline: "2019-06-11T14:00:00+09:00", title: "レポート提出1", memo: ""},
      %{id: 1, deadline: "2019-06-11T14:00:00+09:00", title: "レポート提出2", memo: ""},
      %{id: 2, deadline: "2019-06-11T14:00:00+09:00", title: "レポート提出3", memo: ""}
    ]
  }

  post "/api/v1/event" do
    param = conn.body_params
    {:ok, response} = Jason.encode(@success)
    send_resp(conn, 200, response)
  end

  get "/api/v1/event" do
    {:ok, events} = Jason.encode(@data)
    send_resp(conn, 200, events)
  end

  get "/api/v1/event/:string_id" do
    id = String.to_integer(string_id)
    if (@data.events |> Enum.any?(fn x -> x.id === id end)) do
      {:ok, event} = Jason.encode(@data.events |> Enum.filter(fn x -> x.id === id end) |> hd)
      send_resp(conn, 200, event)
    else
      send_resp(conn, 404, "Not Found")
    end
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end
end
