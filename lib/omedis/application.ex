defmodule Omedis.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OmedisWeb.Telemetry,
      Omedis.Repo,
      {DNSCluster, query: Application.get_env(:omedis, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Omedis.PubSub},
      {AshAuthentication.Supervisor, otp_app: :omedis},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Omedis.Finch},
      {Oban, Application.fetch_env!(:omedis, Oban)},
      # Start a worker by calling: Omedis.Worker.start_link(arg)
      # {Omedis.Worker, arg},
      # Start to serve requests, typically the last entry
      OmedisWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Omedis.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OmedisWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
