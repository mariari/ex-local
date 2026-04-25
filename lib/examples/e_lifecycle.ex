defmodule ELifecycle do
  @moduledoc """
  I am the Lifecycle examples. I exercise the per-kind nodes and
  their derived neighbor info.
  """

  use ExExample
  import ExUnit.Assertions

  alias LocalUpload.Lifecycle

  def rerun?(_), do: true

  @spec build() :: Lifecycle.t()
  example build do
    l = Lifecycle.build()

    assert length(l.controllers) > 0
    assert length(l.contexts) > 0
    assert length(l.event_types) > 0
    assert length(l.ets_tables) > 0

    l
  end

  @spec contexts_are_derived() :: [String.t()]
  example contexts_are_derived do
    l = build()
    labels = l.contexts |> Enum.map(& &1.label) |> Enum.sort()
    assert labels == ["Comments", "Thumbnails", "Uploads", "Votes"]
    labels
  end

  @spec event_type_carries_its_blast_radius() :: Lifecycle.EventType.t()
  example event_type_carries_its_blast_radius do
    l = build()
    fd = Enum.find(l.event_types, &(&1.name == "file_deleted"))

    # Producer attached
    assert Enum.map(fd.producers, &(Module.split(&1) |> List.last())) == ["Uploads"]

    # Tables it writes — sorted to make the assertion stable
    table_names = fd.writes |> Enum.map(fn {t, _op} -> t end) |> Enum.sort()
    assert table_names == [:local_upload_comments, :local_upload_uploads, :local_upload_votes]

    # Downstream readers
    reader_names =
      fd.downstream_readers |> Enum.map(&(Module.split(&1) |> List.last())) |> Enum.sort()

    assert reader_names == ["Comments", "Uploads"]

    fd
  end

  @spec context_carries_its_responsibility() :: Lifecycle.Context.t()
  example context_carries_its_responsibility do
    l = build()
    uploads = Enum.find(l.contexts, &(&1.module == LocalUpload.Uploads))

    inbound_short =
      uploads.inbound |> Enum.map(&(Module.split(&1) |> List.last())) |> MapSet.new()

    assert "PomfController" in inbound_short
    assert "UploadController" in inbound_short
    assert "PageController" in inbound_short
    assert "FileController" in inbound_short

    assert Enum.sort(uploads.produces) == ["file_deleted", "file_uploaded"]
    assert uploads.reads == [:local_upload_uploads]

    uploads
  end

  @spec ets_table_carries_io() :: Lifecycle.EtsTable.t()
  example ets_table_carries_io do
    l = build()
    votes = Enum.find(l.ets_tables, &(&1.name == :local_upload_votes))

    # Written by file_deleted (match_delete) and vote_cast (insert_new)
    assert MapSet.new(votes.written_by) == MapSet.new(["file_deleted", "vote_cast"])

    # No reader — write-only state
    assert votes.read_by == []

    votes
  end

  @spec orphan_ets_finds_votes_table() :: [Lifecycle.EtsTable.t()]
  example orphan_ets_finds_votes_table do
    l = build()
    orphans = Lifecycle.orphan_ets(l)
    assert Enum.any?(orphans, &(&1.name == :local_upload_votes))
    orphans
  end

  @spec orphan_contexts_finds_thumbnails() :: [Lifecycle.Context.t()]
  example orphan_contexts_finds_thumbnails do
    l = build()
    orphans = Lifecycle.orphan_contexts(l)
    assert Enum.any?(orphans, &(&1.module == LocalUpload.Thumbnails))
    orphans
  end

  @spec graph_has_expected_size() :: Graph.t()
  example graph_has_expected_size do
    l = build()
    g = l.graph

    # 8 controllers + 4 contexts + 5 event types + 3 ETS tables = 20
    assert Graph.num_vertices(g) == 20

    # call (7) + produces (5) + writes (8) + reads (2 — table-deduped) = 22
    assert Graph.num_edges(g) == 22

    g
  end
end
