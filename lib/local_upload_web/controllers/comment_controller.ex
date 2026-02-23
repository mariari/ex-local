defmodule LocalUploadWeb.CommentController do
  @moduledoc "I am the CommentController. I handle anonymous comment creation."

  use LocalUploadWeb, :controller

  alias LocalUpload.Comments

  def create(conn, %{"id" => upload_id, "comment" => comment_params}) do
    attrs =
      Map.merge(comment_params, %{
        "upload_id" => upload_id,
        "ip_hash" => conn.assigns.ip_hash
      })

    case Comments.create(attrs) do
      {:ok, _comment} ->
        conn
        |> put_flash(:info, "Comment posted.")
        |> redirect(to: ~p"/uploads/#{upload_id}")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not post comment.")
        |> redirect(to: ~p"/uploads/#{upload_id}")
    end
  end
end
