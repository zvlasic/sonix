defmodule Sonix.Repo do
  use Ecto.Repo,
    otp_app: :sonix,
    adapter: Ecto.Adapters.Postgres
end
