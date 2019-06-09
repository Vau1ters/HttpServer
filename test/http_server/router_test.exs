defmodule HttpServer.RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias HttpServer.Router

  @opts Router.init([])

  @success %{ status: "success", message: "registered", id: 0 }
  @failure %{ status: "failure", message: "invalid date format" }

  @success_delete %{ status: "success", message: "deleted", id: 0}
  @failure_delete %{ status: "failure", message: "invalid id" }

  @todos [
    %{deadline: "2018-07-10T14:00:00+09:00", title:  "レポート提出1", memo: ""},
    %{deadline: "2019-06-10T14:00:00+09:00", title:  "レポート提出2", memo: ""},
    %{deadline: "2019-07-10T14:00:00+09:00", title:  "レポート提出3", memo: ""},
    %{deadline: "2020-06-10T14:00:00+09:00", title:  "レポート提出4", memo: ""}
  ]

  test "post success" do
    conn =
      :post
      |> conn("/api/v1/event", %{deadline: "2019-06-11T14:00:00+09:00", title: "レポート提出", memo: ""})
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    id = Jason.decode!(conn.resp_body)["id"]

    assert conn.state == :sent
    assert conn.resp_body == Jason.encode!(%{@success | id: id})
    assert conn.status == 200
  end

  test "post failure" do
    conn =
      :post
      |> conn("/api/v1/event", %{deadline: "2019-06-11", title: "レポート提出", memo: ""})
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.resp_body == Jason.encode!(@failure)
    assert conn.status == 400
  end

  test "delete all" do
    conn = :delete
           |> conn("/api/v1/event/", "")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.resp_body == Jason.encode!(%{@success_delete | id: "all"})
    assert conn.status == 200
  end

  test "delete success" do
    conn1 = :post
    |> conn("/api/v1/event", %{deadline: "2019-06-11T14:00:00+09:00", title: "レポート提出", memo: ""})
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Router.call(@opts)

    id = Jason.decode!(conn1.resp_body)["id"]

    conn = :delete
           |> conn("/api/v1/event/#{id}", "")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.resp_body == Jason.encode!(%{@success_delete | id: id})
    assert conn.status == 200
  end

  test "delete failure" do
    conn = :delete
           |> conn("/api/v1/event/#{-1}", "")
           |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.resp_body == Jason.encode!(@failure_delete)
    assert conn.status == 400
  end

  test "post and get all" do
    HttpServer.TodoEvent
    |> HttpServer.Repo.delete_all

    conns = @todos |> Enum.map(fn todo -> :post
            |> conn("/api/v1/event", todo)
            |> Plug.Conn.put_req_header("content-type", "application/json")
            |> Router.call(@opts)
    end)


    ids = conns |> Enum.map(fn conn -> Jason.decode!(conn.resp_body)["id"] end)

    conn =
      :get
      |> conn("/api/v1/event", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.resp_body == Enum.zip(@todos, ids) |> Enum.map(fn {x, id} -> Map.put(x, :id, id) end) |> Jason.encode!()
    assert conn.status == 200
  end

  test "post and get from id success" do
    conns = @todos |> Enum.map(fn todo -> 
      :post
      |> conn("/api/v1/event", todo)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Router.call(@opts)
    end)


    ids = conns |> Enum.map(fn conn -> Jason.decode!(conn.resp_body)["id"] end)

    Enum.zip(@todos, ids)
    |> Enum.map(fn {todo, id} ->
      conn =
        :get
        |> conn("/api/v1/event/#{id}", "")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.resp_body == Map.put(todo, :id, id) |> Jason.encode!()
      assert conn.status == 200
    end)
  end

  test "post and get from id failure" do
    conn =
      :get
      |> conn("/api/v1/event/#{-1}", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.resp_body == "Not Found"
    assert conn.status == 404
  end

  test "post and get the specified range of deadline" do
    HttpServer.TodoEvent
    |> HttpServer.Repo.delete_all

    ids = @todos 
          |> Enum.map(fn todo -> 
            :post
            |> conn("/api/v1/event", todo)
            |> Plug.Conn.put_req_header("content-type", "application/json")
            |> Router.call(@opts)
          end)
          |> Enum.map(fn conn -> Jason.decode!(conn.resp_body)["id"] end)

    todo0 = Enum.at(@todos, 0)
    todo1 = Enum.at(@todos, 1)
    todo2 = Enum.at(@todos, 2)
    todo3 = Enum.at(@todos, 3)

    [ 
      {todo1[:deadline], todo2[:deadline], [{todo1, Enum.at(ids, 1)}, {todo2, Enum.at(ids, 2)}]},
      {todo1[:deadline], nil, [{todo1, Enum.at(ids, 1)}, {todo2, Enum.at(ids, 2)}, {todo3, Enum.at(ids, 3)}]},
      {nil, todo2[:deadline], [{todo0, Enum.at(ids, 0)}, {todo1, Enum.at(ids, 1)}, {todo2, Enum.at(ids, 2)}]} 
    ]
    |> Enum.map(fn {from, to, list} ->
      range = if from != nil do
        "?from="<> from <>
          if to != nil do
            "&to=" <> to
          else
            ""
          end
      else
        if to != nil do
          "?to=" <> to
        else
          ""
        end
      end

      conn =
        :get
        |> conn("/api/v1/event/" <> range, "")
        |> Router.call(@opts)

      assert conn.state == :sent
      assert conn.resp_body == Enum.map(list, fn {x, id} -> Map.put(x, :id, id) end) |> Jason.encode!()
      assert conn.status == 200
    end)

  end

  test "returns 404" do
    conn =
      :get
      |> conn("/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
