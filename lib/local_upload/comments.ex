defmodule LocalUpload.Comments do
  @moduledoc """
  I am the Comments context. I manage anonymous comments on uploads.
  I am the essential logic layer for comments.
  """

  import Ecto.Query
  alias LocalUpload.Repo
  alias LocalUpload.Comments.Comment

  ############################################################
  #                        Public API                        #
  ############################################################

  @doc "I create a new comment on an upload."
  @spec create(map()) ::
          {:ok, Comment.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
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
