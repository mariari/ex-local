defmodule EVote do
  @moduledoc """
  I demonstrate voting on uploads and querying the top of the week.
  I build on EUpload.

  ## Example

      iex> {upload, top} = EVote.example()
      iex> upload.vote_count
      2
  """

  import ExUnit.Assertions
  alias LocalUpload.Votes
  alias LocalUpload.Uploads

  @doc """
  I create uploads, vote on them with different IPs, verify
  rate limiting, and check the top-of-week query.
  """
  @spec example() ::
          {LocalUpload.Uploads.Upload.t(), [LocalUpload.Uploads.Upload.t()]}
  def example do
    upload = EUpload.create_example()

    # First vote succeeds
    assert Votes.vote(upload.id, "voter_aaa") == :ok
    # Second vote from different IP succeeds
    assert Votes.vote(upload.id, "voter_bbb") == :ok
    # Same IP voting again is rate-limited
    assert Votes.vote(upload.id, "voter_aaa") == :already_voted

    # Reload to see updated vote count
    refreshed = Uploads.get!(upload.id)
    assert refreshed.vote_count == 2

    # Top of week should include this upload
    top = Uploads.top_of_week(10)
    assert Enum.any?(top, &(&1.id == upload.id))

    {refreshed, top}
  end
end
