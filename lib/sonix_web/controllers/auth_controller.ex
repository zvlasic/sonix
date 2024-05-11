defmodule SonixWeb.AuthController do
  use SonixWeb, :controller

  alias Sonix.LastFmClient

  def callback(conn, %{"token" => token}) do
    with {:ok, %{session: session, username: username}} <- LastFmClient.auth_get_session(token) do
      conn
      |> put_session(:session, session)
      |> put_session(:username, username)
      |> redirect(to: "/")
    end
  end
end
