defmodule LocalUpload.EventStore do
  @moduledoc """
  I am the event store. I manage the append-only event log —
  the essential state of the system. All other data (uploads,
  comments, votes) are projections derived from my events,
  held in ETS by ProjectionStore.
  """

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
end
