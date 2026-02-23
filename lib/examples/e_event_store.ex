defmodule EEventStore do
  @moduledoc """
  I demonstrate the event store. I build incrementally:
  first raw append, then projections, then replay.
  """

  use ExExample
  import ExUnit.Assertions

  alias LocalUpload.EventStore
  alias LocalUpload.EventStore.Event
  alias LocalUpload.Uploads.Upload

  @spec append_raw() :: Event.t()
  example append_raw do
    {:ok, {event, _upload}} =
      EventStore.append(%{
        type: "file_uploaded",
        data: %{
          "original_name" => "event_test.txt",
          "stored_name" => "ev#{System.unique_integer([:positive])}.txt",
          "hash" => "aa#{System.unique_integer([:positive])}",
          "size" => 42,
          "content_type" => "text/plain",
          "uploader" => "mariari"
        }
      })

    assert event.type == "file_uploaded"
    assert event.data["original_name"] == "event_test.txt"
    assert event.inserted_at != nil

    # events are queryable
    found = LocalUpload.Repo.get!(Event, event.id)
    assert found.data == event.data

    event
  end

  @spec append_with_projection() :: Upload.t()
  example append_with_projection do
    stored = "proj#{System.unique_integer([:positive])}.txt"

    {:ok, {_event, upload}} =
      EventStore.append(%{
        type: "file_uploaded",
        data: %{
          "original_name" => "projected.txt",
          "stored_name" => stored,
          "hash" => "bb#{System.unique_integer([:positive])}",
          "size" => 99,
          "content_type" => "text/plain",
          "uploader" => "tester"
        }
      })

    # the projection created an Upload record
    assert %Upload{} = upload
    assert upload.original_name == "projected.txt"
    assert upload.stored_name == stored
    assert upload.uploader == "tester"

    # it's in the DB
    found = LocalUpload.Uploads.get_by_stored_name(stored)
    assert found.id == upload.id

    # comment projection
    {:ok, {_comment_event, comment}} =
      EventStore.append(%{
        type: "comment_added",
        aggregate_id: upload.id,
        data: %{
          "stored_name" => stored,
          "body" => "event-sourced comment",
          "author_name" => "anon",
          "ip_hash" => "abcdef1234567890"
        }
      })

    assert comment.body == "event-sourced comment"
    assert comment.upload_id == upload.id

    # vote projection
    {:ok, {_vote_event, :ok}} =
      EventStore.append(%{
        type: "vote_cast",
        aggregate_id: upload.id,
        data: %{
          "stored_name" => stored,
          "ip_hash" => "voter123456789ab"
        }
      })

    refreshed = LocalUpload.Uploads.get!(upload.id)
    assert refreshed.vote_count == 1

    # duplicate vote
    {:ok, {_dup_event, :already_voted}} =
      EventStore.append(%{
        type: "vote_cast",
        aggregate_id: upload.id,
        data: %{
          "stored_name" => stored,
          "ip_hash" => "voter123456789ab"
        }
      })

    still_one = LocalUpload.Uploads.get!(upload.id)
    assert still_one.vote_count == 1

    upload
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
