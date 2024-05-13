defmodule Sonix.Accounts do
  import Ecto.Query, warn: false

  alias Sonix.Repo
  alias Sonix.Accounts.{User, UserToken}

  def get_user_by_username(username), do: Repo.get_by(User, username: username)

  def register_user(username), do: Repo.insert(%User{username: username})

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_query(token))
    :ok
  end
end
