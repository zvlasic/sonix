defmodule SonixWeb.AuthController do
  use SonixWeb, :controller

  alias Sonix.{Accounts, LastFmClient}
  alias SonixWeb.UserAuth

  def callback(conn, %{"token" => token}) do
    with {:ok, %{session: _session, username: username}} <- LastFmClient.auth_get_session(token) do
      case Accounts.get_user_by_username(username) do
        nil ->
          case Accounts.register_user(username) do
            {:ok, user} ->
              UserAuth.log_in_user(conn, user)

            {:error, _changeset} ->
              conn
              |> put_flash(:error, "Failed to create user.")
              |> redirect(to: ~p"/")
          end

        user ->
          UserAuth.log_in_user(conn, user)
      end
    end
  end
end
