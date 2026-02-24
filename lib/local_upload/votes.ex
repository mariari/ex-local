defmodule LocalUpload.Votes do
  @moduledoc """
  I am the Votes context. I manage thumbs-up voting with IP-based
  rate limiting. I am the essential logic layer for votes.
  """

  alias LocalUpload.EventStore

  ############################################################
  #                        Public API                        #
  ############################################################

  @doc """
  I record a vote for an upload from a given IP hash.

  I return `:ok` if the vote was recorded, or `:already_voted` if
  this IP already voted on this upload. Rate limiting is enforced
  by the database unique index.
  """
  @spec vote(String.t(), String.t()) :: :ok | :already_voted
  def vote(stored_name, ip_hash) do
    upload = LocalUpload.Uploads.get!(stored_name)

    {:ok, {_event, result}} =
      EventStore.append(%{
        type: "vote_cast",
        aggregate_id: upload.id,
        data: %{
          "stored_name" => upload.stored_name,
          "ip_hash" => ip_hash
        }
      })

    result
  end
end
