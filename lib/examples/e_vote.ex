defmodule EVote do
  @moduledoc """
  I demonstrate voting on uploads and querying the top of the week.
  I build on EUpload.
  """

  use ExExample
  import ExUnit.Assertions

  alias LocalUpload.Votes
  alias LocalUpload.Uploads
  alias LocalUpload.Uploads.Upload

  @spec vote_on_upload() :: Upload.t()
  example vote_on_upload do
    upload = EUpload.create_upload()

    assert Votes.vote(upload.stored_name, "voter_aaa") == :ok
    assert Votes.vote(upload.stored_name, "voter_bbb") == :ok
    assert Votes.vote(upload.stored_name, "voter_aaa") == :already_voted

    refreshed = Uploads.get!(upload.stored_name)
    assert refreshed.vote_count == 2

    refreshed
  end

  @spec top_of_week() :: [Upload.t()]
  example top_of_week do
    upload = vote_on_upload()
    top = Uploads.top_of_week(10)
    assert Enum.any?(top, &(&1.stored_name == upload.stored_name))
    top
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
