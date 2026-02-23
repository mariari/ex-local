defmodule LocalUploadWeb.FileController do
  @moduledoc "I am the FileController. I serve uploaded files from disk."

  use LocalUploadWeb, :controller

  alias LocalUpload.Uploads

  @doc "I serve a stored file by its stored name."
  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"name" => name}) do
    path = Uploads.file_path(name)

    if File.exists?(path) do
      content_type = MIME.from_path(name)

      conn
      |> put_resp_content_type(content_type)
      |> send_file(200, path)
    else
      conn
      |> put_status(404)
      |> text("File not found")
    end
  end
end
