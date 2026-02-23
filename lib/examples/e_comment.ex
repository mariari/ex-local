defmodule EComment do
  @moduledoc """
  I demonstrate adding and listing comments on an upload.
  I build on EUpload.

  ## Example

      iex> {upload, comments} = EComment.example()
      iex> length(comments)
      2
  """

  import ExUnit.Assertions
  alias LocalUpload.Comments

  @doc """
  I create an upload, add two comments, and return both the
  upload and the list of comments.
  """
  @spec example() :: {LocalUpload.Uploads.Upload.t(), [LocalUpload.Comments.Comment.t()]}
  def example do
    upload = EUpload.create_example()

    {:ok, c1} =
      Comments.create(%{
        body: "nice vomit!",
        author_name: "anon",
        upload_id: upload.id,
        ip_hash: "abcdef1234567890"
      })

    {:ok, c2} =
      Comments.create(%{
        body: "truly disgusting, 10/10",
        upload_id: upload.id,
        ip_hash: "1234567890abcdef"
      })

    assert c1.body == "nice vomit!"
    assert c1.author_name == "anon"
    assert c2.author_name == "Anonymous"

    comments = Comments.list_for_upload(upload.id)
    assert length(comments) == 2

    # Comments are ordered oldest first
    assert hd(comments).body == "nice vomit!"

    {upload, comments}
  end
end
