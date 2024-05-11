defmodule SonixWeb.SonixLive do
  alias Sonix.LastFmClient
  use SonixWeb, :live_view

  def mount(_params, session, socket) do
    username = session["username"]
    {:ok, assign(socket, username: username, artists: [])}
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <h1>Welcome to Sonix!</h1>
      <.button id="auth" phx-click="auth">Log in with Last.FM</.button>
      <form phx-submit="users_top_artists">
        <.input
          type="select"
          name="period"
          options={[
            {"Overall", "overall"},
            {"7 days", "7day"},
            {"1 month", "1month"},
            {"3 month", "3month"},
            {"6 month", "6month"},
            {"12 months", "12month"}
          ]}
          value="overall"
        />

        <.button>GO!</.button>
      </form>
      <form>
        <.table id="artists" rows={@artists}>
          <:col :let={artist} label="Artist"><%= artist.name %></:col>
          <:col :let={artist} label="Playcount"><%= artist.playcount %></:col>
          <:col :let={artist}>
            <.input
              name="toggle_favorite"
              type="checkbox"
              phx-click="toggle_favorite"
              phx-value-artist-name={artist.name}
              checked={artist.favorite}
            />
          </:col>
        </.table>
      </form>
    </div>
    """
  end

  def handle_event("auth", _, socket),
    do: {:noreply, redirect(socket, external: LastFmClient.oauth_url())}

  def handle_event("users_top_artists", %{"period" => period}, socket) do
    username = socket.assigns.username

    with {:ok, artists} <- LastFmClient.user_top_artists(username, period) do
      artists = Enum.map(artists, fn artist -> Map.merge(artist, %{favorite: true}) end)
      {:noreply, assign(socket, artists: artists)}
    end
  end

  def handle_event("toggle_favorite", %{"artist-name" => artist_name}, socket) do
    artists =
      Enum.map(socket.assigns.artists, fn
        %{name: ^artist_name} = artist -> Map.put(artist, :favorite, !artist.favorite)
        artist -> artist
      end)

    {:noreply, assign(socket, :artists, artists)}
  end
end
