defmodule LocalUpload.ProjectionStore do
  @moduledoc """
  I am the projection store. I own ETS tables for derived data
  and serialize all writes through my GenServer process. Reads
  go directly to ETS — no bottleneck.
  """

  use GenServer

  alias LocalUpload.EventStore.Event
  alias LocalUpload.Uploads.Upload
  alias LocalUpload.Comments.Comment

  @uploads :local_upload_uploads
  @comments :local_upload_comments
  @votes :local_upload_votes

  ############################################################
  #                        Public API                        #
  ############################################################

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []),
    do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "I project a single event (serialized)."
  @spec project(Event.t()) :: any()
  def project(%Event{} = event),
    do: GenServer.call(__MODULE__, {:project, event})

  @doc "I clear all tables and replay from the event log (serialized)."
  @spec rebuild() :: :ok
  def rebuild, do: GenServer.call(__MODULE__, :rebuild, :infinity)

  @doc "I look up an upload by stored_name."
  @spec get_upload(String.t()) :: Upload.t() | nil
  def get_upload(stored_name) do
    case :ets.lookup(@uploads, stored_name) do
      [{_, upload}] -> upload
      [] -> nil
    end
  end

  @doc "I return all uploads, most recent first."
  @spec list_uploads() :: [Upload.t()]
  def list_uploads do
    :ets.tab2list(@uploads)
    |> Enum.map(&elem(&1, 1))
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
  end

  @doc "I find an upload by SHA-1 hash."
  @spec find_by_hash(String.t()) :: Upload.t() | nil
  def find_by_hash(hash) do
    :ets.select(@uploads, [{{:_, %{hash: hash}}, [], [:"$_"]}])
    |> case do
      [{_, upload} | _] -> upload
      [] -> nil
    end
  end

  @doc "I return all comments for an upload, oldest first."
  @spec list_comments(String.t()) :: [Comment.t()]
  def list_comments(stored_name) do
    :ets.match_object(@comments, {{stored_name, :_}, :_})
    |> Enum.map(&elem(&1, 1))
  end

  ############################################################
  #                        Callbacks                         #
  ############################################################

  @impl true
  def init(_opts) do
    :ets.new(@uploads, [:set, :public, :named_table, read_concurrency: true])
    :ets.new(@comments, [:ordered_set, :public, :named_table, read_concurrency: true])
    :ets.new(@votes, [:set, :public, :named_table, read_concurrency: true])
    {:ok, %{wm: do_replay()}}
  end

  @impl true
  def handle_call({:project, %Event{id: id}}, _from, %{wm: wm} = s) when id <= wm,
    do: {:reply, :already_projected, s}

  def handle_call({:project, event}, _from, state),
    do: {:reply, do_project(event), state}

  def handle_call(:rebuild, _from, state) do
    :ets.delete_all_objects(@uploads)
    :ets.delete_all_objects(@comments)
    :ets.delete_all_objects(@votes)
    {:reply, :ok, %{state | wm: do_replay()}}
  end

  ############################################################
  #                   Private Implementation                 #
  ############################################################

  defp do_project(%Event{type: "file_uploaded", data: data}) do
    upload = Upload.new(data)
    :ets.insert(@uploads, {upload.stored_name, upload})
    upload
  end

  defp do_project(%Event{type: "comment_added", data: data, id: event_id}) do
    comment = Comment.new(data, event_id)
    :ets.insert(@comments, {{comment.stored_name, comment.mono_id}, comment})
    comment
  end

  defp do_project(%Event{type: "file_deleted", data: data}) do
    name = data["stored_name"]
    :ets.delete(@uploads, name)
    :ets.match_delete(@comments, {{name, :_}, :_})
    :ets.match_delete(@votes, {{name, :_}, :_})
    :ok
  end

  defp do_project(%Event{type: "vote_cast", data: data}) do
    key = {data["stored_name"], data["ip_hash"]}

    case :ets.insert_new(@votes, {key, true}) do
      true ->
        case :ets.lookup(@uploads, data["stored_name"]) do
          [{k, upload}] ->
            :ets.insert(@uploads, {k, %{upload | vote_count: upload.vote_count + 1}})

          [] ->
            :ok
        end

        :ok

      false ->
        :already_voted
    end
  end

  defp do_replay do
    import Ecto.Query

    events = Event |> order_by(asc: :id) |> LocalUpload.Repo.all()
    Enum.each(events, &do_project/1)

    List.last(events)
    |> then(fn
      nil -> 0
      e -> e.id
    end)
  end
end
