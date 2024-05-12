defmodule Sonix.OpenAiClient do
  @url "https://api.openai.com/v1/chat/completions"

  def stream(prompt) do
    body = prompt |> body() |> Jason.encode!()
    headers = headers()

    Stream.resource(
      fn -> HTTPoison.post!(@url, body, headers, stream_to: self(), async: :once) end,
      &handle_async_response/1,
      &close_async_response/1
    )
  end

  defp close_async_response(resp), do: :hackney.stop_async(resp)
  defp handle_async_response({:done, resp}), do: {:halt, resp}

  defp handle_async_response(%HTTPoison.AsyncResponse{id: id} = resp) do
    receive do
      %HTTPoison.AsyncStatus{id: ^id} ->
        HTTPoison.stream_next(resp)
        {[], resp}

      %HTTPoison.AsyncHeaders{id: ^id} ->
        HTTPoison.stream_next(resp)
        {[], resp}

      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
        HTTPoison.stream_next(resp)
        parse_chunk(chunk, resp)

      %HTTPoison.AsyncEnd{id: ^id} ->
        {:halt, resp}
    end
  end

  defp parse_chunk(chunk, resp) do
    {chunk, done?} =
      chunk
      |> String.split("data:")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.reduce({"", false}, fn trimmed, {chunk, is_done?} ->
        case Jason.decode(trimmed) do
          {:ok, %{"choices" => [%{"delta" => %{"content" => text}}]}} ->
            {chunk <> text, is_done? or false}

          {:ok, %{"choices" => [%{"delta" => _delta}]}} ->
            {chunk, is_done? or false}

          {:error, %{data: "[DONE]"}} ->
            {chunk, is_done? or true}
        end
      end)

    if done?,
      do: {[chunk], {:done, resp}},
      else: {[chunk], resp}
  end

  defp headers do
    [
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: "Bearer #{Sonix.Config.open_ai_key()}"
    ]
  end

  defp body(prompt) do
    %{
      model: "gpt-3.5-turbo",
      messages: [%{role: "user", content: prompt}],
      stream: true,
      max_tokens: 1024
    }
  end
end
