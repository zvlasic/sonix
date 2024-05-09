defmodule SonixWeb.SonixLive do
  use SonixWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <h1>Welcome to Sonix!</h1>
      <p>
        This is a live view. It's like a Phoenix controller, but it's
        stateful and it can push updates to the client.
      </p>
    </div>
    """
  end
end
