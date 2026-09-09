defmodule Scouter.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ScouterWeb.Telemetry,
      Scouter.Repo,
      {DNSCluster, query: Application.get_env(:scouter, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Scouter.PubSub},
      Scouter.Refresher,
      ScouterWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Scouter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ScouterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
