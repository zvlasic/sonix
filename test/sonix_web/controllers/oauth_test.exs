defmodule SonixWeb.OAuthControllerTest do
  use SonixWeb.ConnCase
  alias Sonix.LastFmClient
  import Mox

  setup :verify_on_exit!

  describe "Oauth mechanism" do
    test "redirects to main page if successful", %{conn: conn} do
      expect(LastFmClient.Test, :auth_get_session, fn vars ->
        assert vars == "1234"
        {:ok, %{session: "session", username: "username"}}
      end)

      conn = get(conn, ~p"/callback?token=1234")

      assert redirected_to(conn) == "/"
    end
  end
end
