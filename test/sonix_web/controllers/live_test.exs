defmodule SonixWeb.LiveTest do
  use SonixWeb.ConnCase, async: true
  alias Sonix.Config
  import Phoenix.LiveViewTest

  describe "Live view test" do
    test "properly redirects", %{conn: conn} do
      {:ok, view, html} = conn |> get("/") |> live()
      assert html =~ "Welcome to Sonix!"

      {:error, {:redirect, %{to: redirect_url}}} =
        view |> element("button#auth") |> render_click()

      assert redirect_url ==
               "http://www.last.fm/api/auth/?api_key=#{Config.last_fm_api_key()}&cb=#{Config.last_fm_callback()}"
    end
  end
end
