defmodule LocalUpload.EventStore do
  @moduledoc """
  I am the event store. I manage the append-only event log —
  the essential state of the system. All other tables (uploads,
  comments, votes) are projections derived from my events.
  """

  import Ecto.Query
  alias LocalUpload.Repo
  alias LocalUpload.EventStore.Event
  alias LocalUpload.Uploads.Upload
  alias LocalUpload.Comments.Comment
  alias LocalUpload.Votes.Vote

  ############################################################
  #                        Public API                        #
  ############################################################

  @doc """
  I append an event and apply its projection in a transaction.

  Returns `{:ok, {event, projection_result}}` on success.
  """
  @spec append(map()) :: {:ok, {Event.t(), any()}} | {:error, Ecto.Changeset.t()}
  def append(attrs) do
    Repo.transaction(fn ->
      case %Event{} |> Event.changeset(attrs) |> Repo.insert() do
        {:ok, event} ->
          result = project(event)
          {event, result}

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc "I rebuild all projections by replaying every event in order."
  @spec replay() :: :ok
  def replay do
    Repo.transaction(fn ->
      clear_projections()

      Event
      |> order_by([e], asc: e.id)
      |> Repo.all()
      |> Enum.each(&project/1)
    end)

    :ok
  end

  @doc "I return all events for a given aggregate, ordered by time."
  @spec stream(integer()) :: [Event.t()]
  def stream(aggregate_id) do
    Event
    |> where([e], e.aggregate_id == ^aggregate_id)
    |> order_by([e], asc: e.id)
    |> Repo.all()
  end

  ############################################################
  #                       Projections                        #
  ############################################################

  @spec project(Event.t()) :: any()
  defp project(%Event{type: "file_uploaded", data: data}) do
    %Upload{}
    |> Upload.changeset(data)
    |> Repo.insert!()
  end

  defp project(%Event{type: "comment_added", data: data}) do
    upload = Repo.get_by!(Upload, stored_name: data["stored_name"])

    %Comment{}
    |> Comment.changeset(Map.put(data, "upload_id", upload.id))
    |> Repo.insert!()
  end

  defp project(%Event{type: "vote_cast", data: data}) do
    upload = Repo.get_by!(Upload, stored_name: data["stored_name"])

    case Repo.insert(
           %Vote{upload_id: upload.id, ip_hash: data["ip_hash"]},
           on_conflict: :nothing,
           conflict_target: [:upload_id, :ip_hash]
         ) do
      {:ok, %Vote{id: nil}} ->
        :already_voted

      {:ok, _vote} ->
        Upload
        |> where([u], u.id == ^upload.id)
        |> Repo.update_all(inc: [vote_count: 1])

        :ok
    end
  end

  @spec clear_projections() :: any()
  defp clear_projections do
    Repo.delete_all(Vote)
    Repo.delete_all(Comment)
    Repo.delete_all(Upload)
  end
end
