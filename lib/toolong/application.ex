defmodule Toolong.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Toolong.Repo,
      # Start the Telemetry supervisor
      ToolongWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Toolong.PubSub},
      # Start the Endpoint (http/https)
      ToolongWeb.Endpoint
      # Start a worker by calling: Toolong.Worker.start_link(arg)
      # {Toolong.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Toolong.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ToolongWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
