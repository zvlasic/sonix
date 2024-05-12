defmodule Sonix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Sonix.Config.validate!()

    children = [
      Sonix.Repo,
      {Phoenix.PubSub, name: Sonix.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Sonix.Finch},
      # Start a worker by calling: Sonix.Worker.start_link(arg)
      # {Sonix.Worker, arg},
      # Start to serve requests, typically the last entry
      SonixWeb.Endpoint,
      {Task.Supervisor, name: Sonix.TaskSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sonix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SonixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
