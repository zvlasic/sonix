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
              playcount: integer()
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

      with {:ok, %Req.Response{body: body, status: 200}} <- Req.get(url),
           {:ok, artists} <- Map.fetch(body, "topartists"),
           {:ok, artist_list} <- Map.fetch(artists, "artist") do
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

      case Req.post(url, form: params, headers: headers) do
        {:ok, %Req.Response{body: body, status: 200}} ->
          %{"session" => %{"name" => name, "key" => key}} = body
          {:ok, %{session: key, username: name}}

        error ->
          normalize_error_response(error)
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
        {playcount, _} = Integer.parse(artist["playcount"])

        %{
          name: artist["name"],
          playcount: playcount
        }
      end)
    end

    defp normalize_error_response({:ok, %Req.Response{body: body}}),
      do: {:error, Jason.decode!(body, keys: :atoms).message}

    defp normalize_error_response(error), do: error
  end

  if Mix.env() == :test do
    Mox.defmock(Sonix.LastFmClient.Test, for: Sonix.LastFmClient.Behaviour)
  end
end
