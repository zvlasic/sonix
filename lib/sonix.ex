defmodule Sonix do
  alias Sonix.LastFmClient

  def top_artist_names(user_name) do
    load_top_artists(user_name)
    |> Enum.map(fn {:ok, artists} -> artists end)
    |> Enum.flat_map(fn artists -> Enum.map(artists, fn artist -> artist.name end) end)
    |> Enum.uniq()
  end

  defp load_top_artists(user_name) do
    Enum.map(
      ["overall", "7day", "1month", "3month", "6month", "12month"],
      &LastFmClient.user_top_artists(user_name, &1)
    )
  end
end
