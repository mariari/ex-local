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
    upload = fresh_upload()

    assert Uploads.get_by_stored_name(upload.stored_name) != nil
    :ok = Uploads.delete(upload.stored_name)
    assert Uploads.get_by_stored_name(upload.stored_name) == nil

    :ok
  end

  @spec event_log_preserves_history() :: :ok
  example event_log_preserves_history do
    upload = fresh_upload()
    :ok = Uploads.delete(upload.stored_name)

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
    upload = fresh_upload()
    :ok = Uploads.delete(upload.stored_name)

    :ok = EventStore.replay()
    assert Uploads.get_by_stored_name(upload.stored_name) == nil

    :ok
  end

  defp fresh_upload do
    id = System.unique_integer([:positive])
    path = Path.join(System.tmp_dir!(), "delete_#{id}.txt")
    File.write!(path, "delete target #{id}")
    plug = %Plug.Upload{path: path, filename: "delete_#{id}.txt", content_type: "text/plain"}
    {:ok, upload} = Uploads.store_file(plug)
    upload
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
