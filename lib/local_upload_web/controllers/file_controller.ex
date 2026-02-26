defmodule LocalUploadWeb.FileController do
  @moduledoc "I am the FileController. I serve uploaded files from disk."

  use LocalUploadWeb, :controller

  alias LocalUpload.Uploads

  @doc "I serve a stored file by its stored name."
  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"name" => name}) do
    if Path.basename(name) != name do
      conn |> put_status(400) |> text("Invalid filename")
    else
      path = Uploads.file_path(name)

      if File.exists?(path) do
        content_type =
          case Uploads.get_by_stored_name(name) do
            %{content_type: ct} -> ct
            nil -> MIME.from_path(name)
          end

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
end
