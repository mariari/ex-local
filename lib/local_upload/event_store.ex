defmodule LocalUpload.EventStore do
  @moduledoc """
  I am the event store. I manage the append-only event log —
  the essential state of the system. All other data (uploads,
  comments, votes) are projections derived from my events,
  held in ETS by ProjectionStore.
  """

  import Ecto.Query
  alias LocalUpload.Repo
  alias LocalUpload.EventStore.Event
  alias LocalUpload.ProjectionStore

  ############################################################
  #                        Public API                        #
  ############################################################

  @doc """
  I append an event and project it into ETS.

  Returns `{:ok, {event, projection_result}}` on success.
  """
  @spec append(map()) :: {:ok, {Event.t(), any()}} | {:error, Ecto.Changeset.t()}
  def append(attrs) do
    case %Event{} |> Event.changeset(attrs) |> Repo.insert() do
      {:ok, event} ->
        result = ProjectionStore.project(event)
        {:ok, {event, result}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc "I rebuild all projections by replaying every event in order."
  @spec replay() :: :ok
  def replay, do: ProjectionStore.rebuild()

  @doc "I return the most recent events, newest first."
  @spec recent(integer()) :: [Event.t()]
  def recent(limit \\ 50) do
    Event
    |> order_by([e], desc: e.id)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc "I return all events for a given aggregate, ordered by time."
  @spec stream(integer()) :: [Event.t()]
  def stream(aggregate_id) do
    Event
    |> where([e], e.aggregate_id == ^aggregate_id)
    |> order_by([e], asc: e.id)
    |> Repo.all()
  end
end
