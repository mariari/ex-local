defmodule LocalUpload.EventStore do
  @moduledoc """
  I am the event store. I manage the append-only event log —
  the essential state of the system. All other tables (uploads,
  comments, votes) are projections derived from my events.
  """

  import Ecto.Query
  alias LocalUpload.Repo
  alias LocalUpload.EventStore.Event

  ############################################################
  #                        Public API                        #
  ############################################################

  @doc "I append an event to the log."
  @spec append(map()) :: {:ok, Event.t()} | {:error, Ecto.Changeset.t()}
  def append(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
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
