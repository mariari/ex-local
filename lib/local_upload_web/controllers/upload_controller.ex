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

  def show(conn, %{"id" => id}) do
    upload = Uploads.get!(id)
    comments = Comments.list_for_upload(upload.id)
    render(conn, :show, upload: upload, comments: comments)
  end
end
