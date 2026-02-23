defmodule LocalUpload.Votes do
  @moduledoc """
  I am the Votes context. I manage thumbs-up voting with IP-based
  rate limiting. I am the essential logic layer for votes.
  """

  alias LocalUpload.Repo
  alias LocalUpload.Votes.Vote
  alias LocalUpload.Uploads.Upload
  import Ecto.Query

  ############################################################
  #                        Public API                        #
  ############################################################

  @doc """
  I record a vote for an upload from a given IP hash.

  I return `:ok` if the vote was recorded, or `:already_voted` if
  this IP already voted on this upload. Rate limiting is enforced
  by the database unique index.
  """
  @spec vote(integer(), String.t()) :: :ok | :already_voted
  def vote(upload_id, ip_hash) do
    result =
      Repo.transaction(fn ->
        case Repo.insert(
               %Vote{upload_id: upload_id, ip_hash: ip_hash},
               on_conflict: :nothing,
               conflict_target: [:upload_id, :ip_hash]
             ) do
          {:ok, %Vote{id: nil}} ->
            :already_voted

          {:ok, _vote} ->
            Upload
            |> where([u], u.id == ^upload_id)
            |> Repo.update_all(inc: [vote_count: 1])

            :ok
        end
      end)

    case result do
      {:ok, outcome} -> outcome
    end
  end
end
