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
    assert found.stored_name == upload.stored_name

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

    refreshed = LocalUpload.Uploads.get!(stored)
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

    still_one = LocalUpload.Uploads.get!(stored)
    assert still_one.vote_count == 1

    upload
  end

  @spec replay_rebuilds() :: :ok
  example replay_rebuilds do
    # create state via events
    upload = append_with_projection()
    uploads_before = length(LocalUpload.Uploads.list_recent(100))
    comments_before = length(LocalUpload.Comments.list_for_upload(upload.stored_name))

    assert uploads_before > 0
    assert comments_before > 0

    # snapshot state after events
    pre_replay = LocalUpload.Uploads.get_by_stored_name(upload.stored_name)

    # replay wipes and rebuilds from the event log
    :ok = EventStore.replay()

    # projections are rebuilt — counts match
    uploads_after = length(LocalUpload.Uploads.list_recent(100))
    assert uploads_after == uploads_before

    rebuilt = LocalUpload.Uploads.get_by_stored_name(upload.stored_name)
    assert rebuilt != nil
    assert rebuilt.original_name == upload.original_name
    assert rebuilt.vote_count == pre_replay.vote_count

    comments_after = length(LocalUpload.Comments.list_for_upload(rebuilt.stored_name))
    assert comments_after == comments_before

    :ok
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
