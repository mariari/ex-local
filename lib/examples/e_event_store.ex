defmodule EEventStore do
  @moduledoc """
  I demonstrate the event store. I build incrementally:
  first raw append, then projections, then replay.
  """

  use ExExample
  import ExUnit.Assertions

  alias LocalUpload.EventStore
  alias LocalUpload.EventStore.Event

  @spec append_raw() :: Event.t()
  example append_raw do
    {:ok, event} =
      EventStore.append(%{
        type: "file_uploaded",
        data: %{
          "original_name" => "test.txt",
          "stored_name" => "abc123.txt",
          "hash" => "deadbeef",
          "size" => 42,
          "content_type" => "text/plain",
          "uploader" => "mariari"
        }
      })

    assert event.type == "file_uploaded"
    assert event.data["original_name"] == "test.txt"
    assert event.data["size"] == 42
    assert event.aggregate_id == nil
    assert event.inserted_at != nil

    # events are queryable
    found = LocalUpload.Repo.get!(Event, event.id)
    assert found.data == event.data

    event
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
