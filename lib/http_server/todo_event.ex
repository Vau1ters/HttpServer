defmodule HttpServer.TodoEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todo_events" do
      field :deadline, :string
      field :title, :string
      field :memo, :string, default: ""
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:deadline, :title, :memo])
    |> validate_rfc3339()
  end

  def validate_rfc3339(changeset) do
    deadline = get_field(changeset, :deadline)
    {state, _} = Calendar.DateTime.Parse.rfc3339(deadline, "Asia/Tokyo")

    if(state === :ok) do
      changeset
    else
      add_error(changeset, :deadline, "'s format is not rfc3339")
    end
  end
end
