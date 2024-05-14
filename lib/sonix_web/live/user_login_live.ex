defmodule SonixWeb.UserLoginLive do
  use SonixWeb, :live_view
  alias Sonix.LastFmClient

  def mount(_params, _session, socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center">
      <img src={~p"/images/logo.png"} />
      <.button id="auth" phx-click="oauth">Login using Last.FM</.button>
    </div>
    """
  end

  def handle_event("oauth", _value, socket),
    do: {:noreply, redirect(socket, external: LastFmClient.oauth_url())}
end
