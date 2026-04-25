defmodule LocalUpload.Lifecycle.Trace do
  @moduledoc """
  I observe ETS writes and reads by running a scripted driver against
  the live system with `:dbg` tracing. I return two maps:

      %{
        writes: %{event_type => MapSet[{table, op}]},
        readers: %{reader_fun => table}
      }

  I am the ground-truth counterpart to AST extraction: whatever the
  projection clauses actually touch at runtime is what I see.
  """

  alias LocalUpload.{Comments, Uploads, Votes}

  @ets_write_ops [:insert, :insert_new, :delete, :match_delete, :delete_all_objects]
  @ets_read_ops [:lookup, :match_object, :select, :tab2list, :match]

  @doc """
  I drive events + reads through the system under trace, returning
  the observed write and reader maps. Result is cached in
  `persistent_term` after the first call — use `observe!/0` to force
  a fresh trace.
  """
  @spec observe() :: %{writes: map(), readers: map()}
  def observe do
    case :persistent_term.get({__MODULE__, :cached}, nil) do
      nil -> observe!()
      cached -> cached
    end
  end

  @doc "I always run a fresh trace, updating the cache."
  @spec observe!() :: %{writes: map(), readers: map()}
  def observe! do
    result = do_observe()
    :persistent_term.put({__MODULE__, :cached}, result)
    result
  end

  defp do_observe do
    collector = self()
    tracer_fun = fn msg, st -> send(collector, {:trace, msg}); st end
    :dbg.tracer(:process, {tracer_fun, nil})

    :dbg.p(:all, [:call])
    :dbg.tpl(LocalUpload.ProjectionStore, :do_project, 1, [{:_, [], [{:return_trace}]}])

    for fun <- reader_funs() do
      :dbg.tpl(LocalUpload.ProjectionStore, fun, :_, [{:_, [], [{:return_trace}]}])
    end

    for op <- @ets_write_ops ++ @ets_read_ops do
      :dbg.tpl(:ets, op, :_, [])
    end

    try do
      drive()
      Process.sleep(200)
    after
      :dbg.stop_clear()
    end

    traces = drain_traces([])
    correlate(traces)
  end

  ############################################################
  #                          Driver                          #
  ############################################################

  defp drive do
    {:ok, upload} = do_upload("trace_driver.txt", "text", "text/plain")
    {:ok, _} = Comments.create(%{
      "stored_name" => upload.stored_name,
      "body" => "trace",
      "ip_hash" => "trace_ip"
    })
    :ok = Votes.vote(upload.stored_name, "trace_ip")

    {:ok, img_upload} = do_upload("trace.gif", <<0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00, 0x00, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x21, 0xf9, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x4c, 0x01, 0x00, 0x3b>>, "image/gif")
    Process.sleep(150)

    Uploads.list_recent(10)
    Uploads.get_by_stored_name(upload.stored_name)
    Comments.list_for_upload(upload.stored_name)

    :ok = Uploads.delete(upload.stored_name)
    if Uploads.get_by_stored_name(img_upload.stored_name), do: Uploads.delete(img_upload.stored_name)
  end

  defp do_upload(filename, data, content_type) do
    path = Path.join(System.tmp_dir!(), "lifecycle_trace_#{:erlang.unique_integer([:positive])}")
    File.write!(path, data)
    Uploads.store_file(
      %Plug.Upload{path: path, filename: filename, content_type: content_type},
      "trace"
    )
  end

  defp reader_funs do
    LocalUpload.ProjectionStore.__info__(:functions)
    |> Enum.flat_map(fn
      {:project, 1} -> []
      {:rebuild, 0} -> []
      {:start_link, _} -> []
      {name, _arity} -> [name]
      _ -> []
    end)
    |> Enum.uniq()
  end

  ############################################################
  #                      Trace Collection                    #
  ############################################################

  defp drain_traces(acc) do
    receive do
      {:trace, msg} -> drain_traces([msg | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  ############################################################
  #                       Correlation                        #
  ############################################################

  defp correlate(traces) do
    {_stacks, writes, readers} =
      Enum.reduce(traces, {%{}, %{}, %{}}, &step/2)

    %{writes: writes, readers: readers}
  end

  # call do_project with event
  defp step(
         {:trace, pid, :call, {LocalUpload.ProjectionStore, :do_project, [%{type: type}]}},
         {stacks, writes, readers}
       ) do
    {push(stacks, pid, {:projecting, type}), writes, readers}
  end

  # call a ProjectionStore reader
  defp step(
         {:trace, pid, :call, {LocalUpload.ProjectionStore, fun, args}},
         {stacks, writes, readers}
       )
       when fun != :do_project and fun != :project and is_list(args) do
    {push(stacks, pid, {:reading, fun}), writes, readers}
  end

  # return from either — pop
  defp step(
         {:trace, pid, :return_from, {LocalUpload.ProjectionStore, _, _}, _},
         {stacks, writes, readers}
       ) do
    {pop(stacks, pid), writes, readers}
  end

  # an :ets call — attribute to the top of the pid's stack
  defp step(
         {:trace, pid, :call, {:ets, op, [table | _]}},
         {stacks, writes, readers}
       )
       when is_atom(op) and is_atom(table) do
    case top(stacks, pid) do
      {:projecting, type} when op in @ets_write_ops ->
        {stacks, Map.update(writes, type, MapSet.new([{table, op}]), &MapSet.put(&1, {table, op})),
         readers}

      {:reading, fun} when op in @ets_read_ops ->
        {stacks, writes, Map.put_new(readers, fun, table)}

      _ ->
        {stacks, writes, readers}
    end
  end

  defp step(_, acc), do: acc

  defp push(stacks, pid, frame), do: Map.update(stacks, pid, [frame], &[frame | &1])

  defp pop(stacks, pid) do
    case Map.get(stacks, pid, []) do
      [_ | rest] -> Map.put(stacks, pid, rest)
      [] -> stacks
    end
  end

  defp top(stacks, pid) do
    case Map.get(stacks, pid, []) do
      [frame | _] -> frame
      [] -> nil
    end
  end
end
