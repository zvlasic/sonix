defmodule SonixWeb.SonixLive do
  use SonixWeb, :live_view

  alias Sonix.{LastFmClient, OpenAiClient}

  import SonixWeb.Artists

  def mount(_params, _session, socket) do
    load_ignored_artists(socket.assigns.current_user.username)
    {:ok, assign(socket, artists: [], suggestion: "", ignore_artists: nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <.simple_form id="period_selection" for={} phx-submit="users_top_artists">
        <.input
          type="select"
          name="period"
          label="Select listening period"
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

        <.button>List top artists</.button>
      </.simple_form>
      <section :if={@artists != []}>
        <.artists artists={@artists} />
        <.button phx-click="suggest">Suggest me some music!</.button>
        <div class="pt-2">
          <%= raw(@suggestion) %>
        </div>
      </section>
    </div>
    """
  end

  def handle_event("users_top_artists", %{"period" => period}, socket) do
    username = socket.assigns.current_user.username

    with {:ok, artists} <- LastFmClient.user_top_artists(username, period) do
      artists = Enum.map(artists, fn artist -> Map.merge(artist, %{favorite: true}) end)
      {:noreply, assign(socket, artists: artists, suggestion: "")}
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

  def handle_event("suggest", _params, socket) do
    artist_names = for artist <- socket.assigns.artists, artist.favorite, do: artist.name
    artist_names = Enum.join(artist_names, ", ")

    prompt =
      """
      __ASK__
      Please, suggest me similar to these #{artist_names}.

      __EXAMPLE__
      <h1 class="text-lg font-bold leading-8 text-zinc-800">Artist name</h1>
      <p class="text-base leading-6 text-zinc-600">Reason of similarity</p>

      __CONSTRAINT__
      Please list three artists.
      Output should contain artist name and reason of similarity to artist listed in the prompt.
      Reason should be two or three sentences long.
      """

    prompt
    |> ignore_known_artists_in_prompt(socket.assigns.ignore_artists)
    |> OpenAiClient.stream()
    |> stream_response()

    {:noreply, assign(socket, :suggestion, "")}
  end

  defp ignore_known_artists_in_prompt(prompt, nil), do: prompt

  defp ignore_known_artists_in_prompt(prompt, ignore_artists),
    do: prompt <> "Please don't recommend #{Enum.join(ignore_artists, ", ")}."

  defp stream_response(stream) do
    target = self()

    Task.Supervisor.async(Sonix.TaskSupervisor, fn ->
      for chunk <- stream, into: <<>> do
        send(target, {:render_response_chunk, chunk})
        chunk
      end
    end)
  end

  defp load_ignored_artists(username) do
    target = self()

    Task.Supervisor.async(Sonix.TaskSupervisor, fn ->
      ignored_artists = Sonix.top_artist_names(username)
      send(target, {:ignored_artists, ignored_artists})
    end)
  end

  def handle_info({:ignored_artists, ignored_artists}, socket),
    do: {:noreply, assign(socket, :ignore_artists, ignored_artists)}

  def handle_info({:render_response_chunk, chunk}, socket) do
    suggestion = socket.assigns.suggestion
    suggestion = suggestion <> chunk
    {:noreply, assign(socket, :suggestion, suggestion)}
  end

  def handle_info(_out, socket), do: {:noreply, socket}
end
