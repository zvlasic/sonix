defmodule Sonix.Config do
  use Provider,
    source: Provider.SystemEnv,
    params: [
      {:last_fm_api_key, dev: "last_fm_api_key"}
    ]
end
