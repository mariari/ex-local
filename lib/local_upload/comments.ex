defmodule LocalUpload.Comments do
  @moduledoc """
  I am the Comments context. I manage anonymous comments on uploads.
  I am the essential logic layer for comments.
  """

  alias LocalUpload.Comments.Comment
  alias LocalUpload.EventStore
  alias LocalUpload.ProjectionStore

  ############################################################
  #                        Public API                        #
  ############################################################

  @doc "I create a new comment on an upload."
  @spec create(map()) :: {:ok, Comment.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    stored_name = attrs["stored_name"] || attrs[:stored_name]
    _upload = LocalUpload.Uploads.get!(stored_name)

    case EventStore.append(%{
           type: "comment_added",
           data: %{
             "stored_name" => stored_name,
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
  @spec list_for_upload(String.t()) :: [Comment.t()]
  def list_for_upload(stored_name),
    do: ProjectionStore.list_comments(stored_name)
end
