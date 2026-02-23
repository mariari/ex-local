defmodule LocalUpload.Comments do
  @moduledoc """
  I am the Comments context. I manage anonymous comments on uploads.
  I am the essential logic layer for comments.
  """

  import Ecto.Query
  alias LocalUpload.Repo
  alias LocalUpload.Comments.Comment
  alias LocalUpload.EventStore

  ############################################################
  #                        Public API                        #
  ############################################################

  @doc "I create a new comment on an upload."
  @spec create(map()) ::
          {:ok, Comment.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    upload_id = attrs["upload_id"] || attrs[:upload_id]
    upload = LocalUpload.Uploads.get!(upload_id)

    case EventStore.append(%{
           type: "comment_added",
           aggregate_id: upload.id,
           data: %{
             "stored_name" => upload.stored_name,
             "body" => attrs["body"] || attrs[:body],
             "author_name" => attrs["author_name"] || attrs[:author_name] || "Anonymous",
             "ip_hash" => attrs["ip_hash"] || attrs[:ip_hash]
           }
         }) do
      {:ok, {_event, comment}} -> {:ok, comment}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc "I list all comments for an upload, oldest first."
  @spec list_for_upload(integer()) :: [Comment.t()]
  def list_for_upload(upload_id) do
    Comment
    |> where([c], c.upload_id == ^upload_id)
    |> order_by([c], asc: c.inserted_at)
    |> Repo.all()
  end
end
