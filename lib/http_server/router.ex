defmodule HttpServer.Router do
  use Plug.Router

  plug Plug.Parsers, parsers: [:urlencoded, :json],
                     pass: ["application/json"],
                     json_decoder: Jason
  plug :match
  plug :dispatch

  @success %{ status: "success", message: "registered", id: 0}
  @failure %{ status: "failure", message: "invalid date format" }

  @success_delete %{ status: "success", message: "deleted", id: 0}
  @failure_delete %{ status: "failure", message: "invalid id" }

  post "/api/v1/event" do
    param = conn.body_params

    todo = HttpServer.TodoEvent.changeset(%HttpServer.TodoEvent{}, param)
    if todo.valid? do
      {:ok, struct} = HttpServer.Repo.insert(todo)
      {:ok, response} = Jason.encode(%{@success | id: struct.id})
      send_resp(conn, 200, response)
    else
      {:ok, response} = Jason.encode(@failure)
      send_resp(conn, 400, response)
    end

  end

  get "/api/v1/event" do
    events_data = HttpServer.TodoEvent
                  |> HttpServer.Repo.all
                  |> Enum.map(&event_to_map/1)

    {:ok, events} = Jason.encode(events_data)
    send_resp(conn, 200, events)
  end

  get "/api/v1/delete/:string_id" do
    id = String.to_integer(string_id)
    post = HttpServer.TodoEvent
           |> HttpServer.Repo.get(id)
    if post != nil do
      {status, _} = post |> HttpServer.Repo.delete()
      if status == :ok do
        {:ok, response} = Jason.encode(%{@success_delete | id: id})
        send_resp(conn, 200, response)
      else
        {:ok, response} = Jason.encode(@failure_delete)
        send_resp(conn, 400, response)
      end
    else
      {:ok, response} = Jason.encode(@failure_delete)
      send_resp(conn, 400, response)
    end
  end

  get "/api/v1/event/:string_id" do
    id = String.to_integer(string_id)
    event_row_data = HttpServer.TodoEvent
                     |> HttpServer.Repo.get(id)
    if (event_row_data != nil) do
      event_data = event_row_data |> event_to_map()
      {:ok, event} = Jason.encode(event_data)
      send_resp(conn, 200, event)
    else
      send_resp(conn, 404, "Not Found")
    end
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end

  def event_to_map(todo_event) do
    todo_event
    |> Map.from_struct()
    |> Map.delete(:__meta__)
  end
end
