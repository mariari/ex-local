defmodule LocalUploadWeb.UploadController do
  @moduledoc """
  I am the UploadController. I handle the web UI for browsing
  and viewing individual uploads.
  """

  use LocalUploadWeb, :controller

  alias LocalUpload.Uploads
  alias LocalUpload.Comments

  def index(conn, _params) do
    uploads = Uploads.list_recent(50)
    render(conn, :index, uploads: uploads)
  end

  def show(conn, %{"stored_name" => stored_name}) do
    upload = Uploads.get!(stored_name)
    comments = Comments.list_for_upload(stored_name)
    render(conn, :show, upload: upload, comments: comments)
  end

  def delete(conn, %{"stored_name" => stored_name}) do
    if conn.assigns.authenticated? do
      :ok = Uploads.delete(stored_name)

      conn
      |> put_flash(:info, "File deleted.")
      |> redirect(to: ~p"/")
    else
      conn
      |> put_status(403)
      |> text("Forbidden")
      |> halt()
    end
  end
end
