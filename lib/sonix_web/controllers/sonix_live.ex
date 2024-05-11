defmodule SonixWeb.SonixLive do
  alias Sonix.LastFmClient
  use SonixWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <h1>Welcome to Sonix!</h1>
      <.button id="auth" phx-click="auth">Log in with Last.FM</.button>
    </div>
    """
  end

  def handle_event("auth", _, socket),
    do: {:noreply, redirect(socket, external: LastFmClient.oauth_url())}
end
