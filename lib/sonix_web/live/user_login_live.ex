defmodule SonixWeb.UserLoginLive do
  use SonixWeb, :live_view

  alias Sonix.LastFmClient

  def mount(_params, _session, socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.button id="auth" phx-click="auth">Log in with Last.FM</.button>
    </div>
    """
  end

  def handle_event("auth", _, socket),
    do: {:noreply, redirect(socket, external: LastFmClient.oauth_url())}
end
