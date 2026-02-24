defmodule EDelete do
  @moduledoc """
  I demonstrate event-sourced file deletion. Deletion is an event
  overlay — the event log preserves both upload and delete events,
  but the projection masks deleted uploads.
  """

  use ExExample
  import ExUnit.Assertions

  alias LocalUpload.Uploads
  alias LocalUpload.EventStore

  @spec delete_masks_projection() :: :ok
  example delete_masks_projection do
    upload = EUpload.create_upload()

    # upload is visible
    assert Uploads.get_by_stored_name(upload.stored_name) != nil

    # delete it
    :ok = Uploads.delete(upload.stored_name)

    # projection no longer shows it
    assert Uploads.get_by_stored_name(upload.stored_name) == nil

    :ok
  end

  @spec event_log_preserves_history() :: :ok
  example event_log_preserves_history do
    upload = EUpload.create_upload()
    :ok = Uploads.delete(upload.stored_name)

    # both events are in the log
    events =
      LocalUpload.Repo.all(EventStore.Event)
      |> Enum.filter(&(&1.data["stored_name"] == upload.stored_name))

    types = Enum.map(events, & &1.type)
    assert "file_uploaded" in types
    assert "file_deleted" in types

    :ok
  end

  @spec replay_respects_deletion() :: :ok
  example replay_respects_deletion do
    upload = EUpload.create_upload()
    :ok = Uploads.delete(upload.stored_name)

    # replay from scratch
    :ok = EventStore.replay()

    # still deleted after replay
    assert Uploads.get_by_stored_name(upload.stored_name) == nil

    :ok
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
