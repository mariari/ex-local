defmodule EComment do
  @moduledoc """
  I demonstrate adding and listing comments on an upload.
  I build on EUpload.
  """

  use ExExample
  import ExUnit.Assertions

  alias LocalUpload.Comments
  alias LocalUpload.Comments.Comment
  alias LocalUpload.Uploads.Upload

  @spec add_comments() :: {Upload.t(), [Comment.t()]}
  example add_comments do
    upload = EUpload.create_upload()

    {:ok, c1} =
      Comments.create(%{
        body: "nice vomit!",
        author_name: "anon",
        stored_name: upload.stored_name,
        ip_hash: "abcdef1234567890"
      })

    {:ok, c2} =
      Comments.create(%{
        body: "truly disgusting, 10/10",
        stored_name: upload.stored_name,
        ip_hash: "1234567890abcdef"
      })

    assert c1.body == "nice vomit!"
    assert c1.author_name == "anon"
    assert c2.author_name == "Anonymous"

    {upload, [c1, c2]}
  end

  @spec list_comments() :: [Comment.t()]
  example list_comments do
    {upload, _} = add_comments()
    comments = Comments.list_for_upload(upload.stored_name)
    assert length(comments) >= 2
    assert hd(comments).body == "nice vomit!"
    comments
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
