defmodule LocalUpload.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    upload_dir =
      Application.get_env(:local_upload, :upload_dir, "priv/uploads")

    File.mkdir_p!(upload_dir)

    children = [
      LocalUploadWeb.Telemetry,
      LocalUpload.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:local_upload, :ecto_repos), skip: skip_migrations?()},
      LocalUpload.ProjectionStore,
      LocalUploadWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LocalUpload.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LocalUploadWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @spec skip_migrations?() :: boolean()
  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
