defmodule ExamplesTest do
  @moduledoc """
  I register all ExExample examples as ExUnit tests.

  Examples share state via ExExample's cache and ETS projections,
  so they run sequentially in dependency order within a single
  sandbox transaction.
  """

  use ExUnit.Case

  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(LocalUpload.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(LocalUpload.Repo, {:shared, self()})
    :ok
  end

  test "EUpload" do
    EUpload.create_upload()
    EUpload.retrieve_upload()
    EUpload.dedup_upload()
    EUpload.create_image_upload()
    EUpload.list_recent_uploads()
  end

  test "EComment" do
    EComment.add_comments()
    EComment.list_comments()
  end

  test "EVote" do
    EVote.vote_on_upload()
    EVote.top_of_week()
  end

  test "EEventStore" do
    EEventStore.append_raw()
    EEventStore.append_with_projection()
    EEventStore.replay_rebuilds()
  end

  test "EContentType" do
    EContentType.detect_gif()
    EContentType.detect_jpeg()
    EContentType.detect_png()
    EContentType.fallback_for_unknown()
    EContentType.override_in_upload()
  end

  test "EDelete" do
    EDelete.delete_masks_projection()
    EDelete.event_log_preserves_history()
    EDelete.replay_respects_deletion()
  end

  @tag :http
  test "EWebUI" do
    EWebUI.homepage()
    EWebUI.browse_page()
    EWebUI.show_page()
    EWebUI.vote_via_http()
    EWebUI.comment_via_http()
  end

  @tag :http
  test "EPomfResponse" do
    EPomfResponse.success_response()
    EPomfResponse.error_response()
  end

  @tag :http
  test "EPomfRoundTrip" do
    EPomfRoundTrip.upload_and_download()
    EPomfRoundTrip.file_not_found()
    EPomfRoundTrip.path_traversal_blocked()
  end

  @tag :http
  test "ESecret" do
    ESecret.secret_rejects_bad_request()
    ESecret.secret_accepts_good_request()
    ESecret.open_when_no_secret()
  end
end
