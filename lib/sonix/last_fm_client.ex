defmodule Sonix.LastFmClient do
  alias Sonix.Config

  @last_fm_client if Mix.env() == :test,
                    do: Sonix.LastFmClient.Test,
                    else: Sonix.LastFmClient.Real

  def user_top_artists(user, period), do: @last_fm_client.user_top_artists(user, period)
  def auth_get_session(token), do: @last_fm_client.auth_get_session(token)

  def oauth_url do
    "http://www.last.fm/api/auth/?api_key=#{Config.last_fm_api_key()}&cb=#{Config.last_fm_callback()}"
  end

  defmodule Behaviour do
    @type user :: String.t()
    @type period :: String.t()
    @type token :: String.t()
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

    @type auth_get_session_response :: %{session: String.t(), username: String.t()}

    @callback user_top_artists(user(), period()) ::
                {:ok, user_top_artists_response()} | {:error, String.t()}

    @callback auth_get_session(token()) ::
                {:ok, auth_get_session_response()} | {:error, String.t()}
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

    @impl Sonix.LastFmClient.Behaviour
    def auth_get_session(token) do
      api_sig = generate_signature_string(method: "auth.getSession", token: token)

      params = [
        api_key: Config.last_fm_api_key(),
        token: token,
        api_sig: api_sig,
        format: "json"
      ]

      url = "#{@api_url}?method=auth.getSession"
      headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

      with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <-
             HTTPoison.post(url, {:form, params}, headers),
           {:ok, %{session: %{name: name, key: key}}} <- Jason.decode(body, keys: :atoms) do
        {:ok, %{session: key, username: name}}
      else
        error -> normalize_error_response(error)
      end
    end

    defp generate_signature_string(params) do
      params = [{:api_key, Config.last_fm_api_key()} | params]
      signature_string = Enum.map_join(params, fn {key, value} -> "#{key}#{value}" end)
      signature_with_secret = signature_string <> Config.last_fm_secret()
      :crypto.hash(:md5, signature_with_secret) |> Base.encode16() |> String.downcase()
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
