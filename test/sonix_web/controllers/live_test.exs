defmodule SonixWeb.LiveTest do
  use SonixWeb.ConnCase, async: true
  alias Sonix.{Config, LastFmClient}
  import Phoenix.LiveViewTest
  import Mox

  setup :verify_on_exit!

  describe "Live view test" do
    test "properly redirects", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} = result = live(conn, "/")
      {:ok, conn} = follow_redirect(result, conn)
      {:ok, view, _html} = live(conn)

      {:error, {:redirect, %{to: redirect_url}}} =
        view |> element("button#auth") |> render_click()

      assert redirect_url ==
               "http://www.last.fm/api/auth/?api_key=#{Config.last_fm_api_key()}&cb=#{Config.last_fm_callback()}"
    end

    test "loads screen", %{conn: conn} do
      expect(LastFmClient.Test, :auth_get_session, fn _ ->
        {:ok, %{session: "session", username: "username"}}
      end)

      conn = get(conn, "/callback?token=test_token")
      assert redirected_to(conn, 302) == "/"

      conn = get(recycle(conn), "/")
      {:ok, view, _html} = live(conn)

      expect(LastFmClient.Test, :user_top_artists, fn "username", "1month" ->
        {:ok, [%{name: "artist1", playcount: 100}, %{name: "artist2", playcount: 200}]}
      end)

      submit_artist_search(view, %{"period" => "1month"})
      assert_artist_selected(view, "artist1")
      click_artist(view, "artist1")
      assert_artist_deselected(view, "artist1")
    end
  end

  defp submit_artist_search(view, period),
    do: view |> element("form#period_selection") |> render_submit(period)

  defp click_artist(view, artist_name),
    do: view |> element("div##{artist_name}") |> render_click()

  defp assert_artist_selected(view, artist_name) do
    assert view |> element("div##{artist_name}") |> render() =~ "hero-check"
  end

  defp assert_artist_deselected(view, artist_name) do
    assert view |> element("div##{artist_name}") |> render() =~ "hero-x-mark"
  end
end
