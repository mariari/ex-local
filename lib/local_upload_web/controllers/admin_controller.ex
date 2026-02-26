defmodule LocalUploadWeb.AdminController do
  @moduledoc """
  I am the AdminController. I serve the admin dashboard with
  upload collage and aggregate stats. I require authentication.
  """

  use LocalUploadWeb, :controller

  alias LocalUpload.ProjectionStore
  alias LocalUpload.Repo
  alias LocalUpload.EventStore.Event

  @doc "I render the admin dashboard."
  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    if conn.assigns.authenticated? do
      uploads = ProjectionStore.list_uploads()
      recent = Enum.take(uploads, 100)
      stats = compute_stats(uploads)
      render(conn, :index, uploads: recent, stats: stats)
    else
      conn
      |> put_status(403)
      |> text("Forbidden")
      |> halt()
    end
  end

  @spec compute_stats([LocalUpload.Uploads.Upload.t()]) :: map()
  defp compute_stats(uploads) do
    week_ago = DateTime.add(DateTime.utc_now(), -7, :day)

    %{
      total_files: length(uploads),
      total_size: Enum.reduce(uploads, 0, &(&1.size + &2)),
      uploads_this_week:
        Enum.count(uploads, &(DateTime.compare(&1.inserted_at, week_ago) != :lt)),
      total_events: Repo.aggregate(Event, :count, :id),
      top_uploaders:
        uploads
        |> Enum.frequencies_by(& &1.uploader)
        |> Enum.sort_by(&elem(&1, 1), :desc)
        |> Enum.take(5)
    }
  end
end
