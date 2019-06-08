defmodule HttpServer.Repo.Migrations.CreateTodoEvents do
  use Ecto.Migration

  def change do
    create table(:todo_events) do
      # add :id, :integer, null: false
      add :deadline, :string, null: false
      add :title, :string, null: false
      add :memo, :string, null: false
    end
  end
end
