defmodule Sonix.Config do
  use Provider,
    source: Provider.SystemEnv,
    params: [
      {:last_fm_api_key, dev: "last_fm_api_key"},
      {:last_fm_secret, dev: "last_fm_secret"},
      {:last_fm_callback, dev: "http://localhost:4000/callback"}
    ]
end
