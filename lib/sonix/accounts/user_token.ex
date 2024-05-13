defmodule Sonix.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query
  alias Sonix.Accounts.UserToken

  @rand_size 32
  @session_validity_in_days 60

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_tokens" do
    field :token, :binary
    belongs_to :user, Sonix.Accounts.User

    timestamps(updated_at: false)
  end

  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %UserToken{token: token, user_id: user.id}}
  end

  def verify_session_token_query(token) do
    query =
      from token in by_token_query(token),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: user

    {:ok, query}
  end

  def by_token_query(token), do: from(UserToken, where: [token: ^token])
end
