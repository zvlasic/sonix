defmodule Sonix.Accounts.User do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :username, :string
    timestamps(type: :utc_datetime)
  end
end
