defmodule LocalUploadWeb.AdminController do
  @moduledoc """
  I am the AdminController. I render the admin dashboard for
  auditing uploads, viewing the event log, and managing files.
  """

  use LocalUploadWeb, :controller

  alias LocalUpload.Uploads
  alias LocalUpload.EventStore

  def index(conn, _params) do
    if conn.assigns.authenticated? do
      uploads = Uploads.list_recent(200)
      events = EventStore.recent(50)

      total_size = Enum.reduce(uploads, 0, &(&1.size + &2))

      render(conn, :index,
        uploads: uploads,
        events: events,
        upload_count: length(uploads),
        total_size: total_size
      )
    else
      conn
      |> put_status(403)
      |> text("Forbidden")
      |> halt()
    end
  end
end
