defmodule Sonix.OpenAiClient do
  @url "https://api.openai.com/v1/chat/completions"

  def stream_completion_to_process(prompt, pid) do
    request = %{
      model: "gpt-4o",
      messages: [%{role: "user", content: prompt}],
      stream: true
    }

    Req.post!(@url,
      json: request,
      auth: {:bearer, Sonix.Config.open_ai_key()},
      into: fn {:data, data}, context ->
        split_data = String.split(data, "data: ")

        Enum.each(split_data, fn chunk ->
          chunk
          |> String.trim()
          |> decode_chunk()
          |> send_chunk(pid)
        end)

        {:cont, context}
      end
    )
  end

  defp decode_chunk(""), do: nil
  defp decode_chunk("[DONE]"), do: nil

  defp decode_chunk(chunk) do
    chunk
    |> :json.decode()
    |> Map.get("choices")
    |> hd()
    |> Map.get("delta")
    |> Map.get("content")
  end

  defp send_chunk(nil, _pid), do: :ok
  defp send_chunk(chunk, pid), do: send(pid, {:completion_chunk, chunk})
end
