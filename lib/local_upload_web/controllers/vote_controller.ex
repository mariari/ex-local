defmodule LocalUploadWeb.VoteController do
  @moduledoc "I am the VoteController. I handle thumbs-up voting."

  use LocalUploadWeb, :controller

  alias LocalUpload.Votes

  def create(conn, %{"id" => upload_id}) do
    case Votes.vote(String.to_integer(upload_id), conn.assigns.ip_hash) do
      :ok ->
        conn
        |> put_flash(:info, "Vote recorded!")
        |> redirect(to: ~p"/uploads/#{upload_id}")

      :already_voted ->
        conn
        |> put_flash(:info, "You already voted on this file.")
        |> redirect(to: ~p"/uploads/#{upload_id}")
    end
  end
end
