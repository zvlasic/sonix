defmodule SonixWeb.UserLoginLive do
  use SonixWeb, :live_view

  def mount(_params, _session, socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm"></div>
    """
  end
end
