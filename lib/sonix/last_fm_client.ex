defmodule Sonix.LastFmClient do
  alias Sonix.Config

  @last_fm_client if Mix.env() == :test,
                    do: Sonix.LastFmClient.Test,
                    else: Sonix.LastFmClient.Real

  def user_top_artists(user, period), do: @last_fm_client.user_top_artists(user, period)

  defmodule Behaviour do
    @type user :: String.t()
    @type period :: String.t()
    @type user_top_artists_response :: [
            %{
              name: String.t(),
              playcount: integer(),
              small_image: String.t(),
              medium_image: String.t(),
              large_image: String.t(),
              extra_large_image: String.t(),
              mega_image: String.t()
            }
          ]

    @callback user_top_artists(user(), period()) ::
                {:ok, user_top_artists_response()} | {:error, String.t()}
  end

  defmodule Real do
    @behaviour Sonix.LastFmClient.Behaviour

    @api_url "http://ws.audioscrobbler.com/2.0/"

    @impl Sonix.LastFmClient.Behaviour
    def user_top_artists(user, period) do
      url =
        "#{@api_url}?method=user.gettopartists&format=json&user=#{user}&api_key=#{Config.last_fm_api_key()}&limit=9&period=#{period}"

      with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <- HTTPoison.get(url),
           {:ok, body} <- Jason.decode(body, keys: :atoms),
           {:ok, artists} <- Map.fetch(body, :topartists),
           {:ok, artist_list} <- Map.fetch(artists, :artist) do
        {:ok, normalize_user_top_artists_response(artist_list)}
      else
        error -> normalize_error_response(error)
      end
    end

    defp normalize_user_top_artists_response(artist_list) do
      Enum.map(artist_list, fn artist ->
        {playcount, _} = Integer.parse(artist.playcount)

        images =
          Map.new(artist.image, fn %{size: size, "#text": url} -> {String.to_atom(size), url} end)

        %{
          name: artist.name,
          playcount: playcount,
          small_image: images.small,
          medium_image: images.medium,
          large_image: images.large,
          extra_large_image: images.extralarge,
          mega_image: images.mega
        }
      end)
    end

    defp normalize_error_response({:ok, %HTTPoison.Response{body: body}}),
      do: {:error, Jason.decode!(body, keys: :atoms).message}

    defp normalize_error_response(error), do: error
  end

  if Mix.env() == :test do
    Mox.defmock(Sonix.LastFmClient.Test, for: Sonix.LastFmClient.Behaviour)
  end
end
