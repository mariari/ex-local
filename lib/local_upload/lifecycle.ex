defmodule LocalUpload.Lifecycle do
  @moduledoc """
  I am the Lifecycle graph. I describe how a request flows through
  the system:

      Controller --call--> Context --produces--> EventType --writes--> EtsTable
                                                                            |
                            Context <--reads--------------------------------+

  EventStore and ProjectionStore are architectural invariants (every
  write goes through `EventStore.append/1`; every read through
  `ProjectionStore`'s public API) and are not drawn as nodes.

  ### Public API

  - `build/0` — derive the current lifecycle from the codebase
  - `producers_of/2`, `tables_reached_by/2` — targeted queries
  - `orphan_ets/1`, `orphan_contexts/1` — architectural lint
  """

  use TypedStruct
  use GtBridge.View

  alias GtBridge.Analysis
  alias GtBridge.Phlow.ColumnedList
  alias GtBridge.Phlow.Mondrian
  alias GtBridge.Phlow.Text

  ############################################################
  #                      Per-Kind Nodes                      #
  ############################################################

  typedstruct module: Controller do
    field :module, module(), enforce: true
    field :label, String.t(), enforce: true
    field :routes, [String.t()], default: []
    field :calls, [module()], default: []
  end

  typedstruct module: Context do
    field :module, module(), enforce: true
    field :label, String.t(), enforce: true
    field :inbound, [module()], default: []
    field :produces, [String.t()], default: []
    field :reads, [atom()], default: []
  end

  typedstruct module: EventType do
    field :name, String.t(), enforce: true
    field :producers, [module()], default: []
    field :writes, [{atom(), atom()}], default: []
    field :downstream_readers, [module()], default: []
    field :count, integer() | nil, default: nil
  end

  typedstruct module: EtsTable do
    field :name, atom(), enforce: true
    field :written_by, [String.t()], default: []
    field :read_by, [module()], default: []
    field :size, integer() | nil, default: nil
  end

  ############################################################
  #                       Lifecycle                          #
  ############################################################

  typedstruct do
    field :graph, Graph.t(), enforce: true
    field :controllers, [Controller.t()], default: []
    field :contexts, [Context.t()], default: []
    field :event_types, [EventType.t()], default: []
    field :ets_tables, [EtsTable.t()], default: []
  end

  @app :local_upload
  @router LocalUploadWeb.Router
  @projection_module LocalUpload.ProjectionStore
  @event_store LocalUpload.EventStore

  @doc """
  I derive the lifecycle from xref (call graph), AST (event type +
  table enumeration + append call sites), and runtime tracing
  (projection writes + reader→table mapping).

  The trace fires real events through the system — each `build/0`
  appends a few rows to the event log and writes to ETS. Acceptable
  for dev/introspection; not for production hot paths.
  """
  @spec build() :: t()
  def build do
    ets_attrs = ets_attrs(@projection_module)
    event_types = event_types(@projection_module)

    %{writes: observed_writes, readers: reader_map} = LocalUpload.Lifecycle.Trace.observe()
    writes_per_event = Map.new(observed_writes, fn {t, set} -> {t, MapSet.to_list(set)} end)

    producers = contexts_calling(@event_store)
    readers = contexts_calling(@projection_module)
    contexts = Enum.uniq(producers ++ readers)

    routes = Enum.to_list(@router.__routes__())
    controllers_mods = routes |> Enum.map(& &1.plug) |> Enum.uniq()

    appends_per_ctx = Map.new(producers, &{&1, Enum.uniq(event_store_appends(&1))})

    reader_calls_per_ctx =
      Map.new(readers, &{&1, Enum.uniq(projection_reader_calls(&1, Map.keys(reader_map)))})

    ctx_set = MapSet.new(contexts)
    calls_per_ctrl = Map.new(controllers_mods, &{&1, ctrl_calls(&1, ctx_set)})

    controllers = build_controllers(controllers_mods, routes, calls_per_ctrl)

    ctx_structs =
      build_contexts(contexts, calls_per_ctrl, appends_per_ctx, reader_calls_per_ctx, reader_map)

    et_structs =
      build_event_types(
        event_types,
        appends_per_ctx,
        writes_per_event,
        reader_calls_per_ctx,
        reader_map
      )

    ets_structs = build_ets_tables(ets_attrs, writes_per_event, reader_calls_per_ctx, reader_map)

    graph = build_graph(controllers, ctx_structs, et_structs, ets_structs)

    %__MODULE__{
      graph: graph,
      controllers: controllers,
      contexts: ctx_structs,
      event_types: et_structs,
      ets_tables: ets_structs
    }
  end

  @doc "I list contexts that produce the given event type."
  @spec producers_of(t(), String.t()) :: [module()]
  def producers_of(%__MODULE__{} = l, event_type) do
    case Enum.find(l.event_types, &(&1.name == event_type)) do
      nil -> []
      et -> et.producers
    end
  end

  @doc "I list ETS tables read by the given context module."
  @spec tables_reached_by(t(), module()) :: [atom()]
  def tables_reached_by(%__MODULE__{} = l, context_module) do
    case Enum.find(l.contexts, &(&1.module == context_module)) do
      nil -> []
      c -> c.reads
    end
  end

  @doc "I return ETS tables with no reader."
  @spec orphan_ets(t()) :: [EtsTable.t()]
  def orphan_ets(%__MODULE__{} = l), do: Enum.filter(l.ets_tables, &(&1.read_by == []))

  @doc "I return contexts with no controller calling them."
  @spec orphan_contexts(t()) :: [Context.t()]
  def orphan_contexts(%__MODULE__{} = l), do: Enum.filter(l.contexts, &(&1.inbound == []))

  ############################################################
  #                   Lifecycle-level Views                  #
  ############################################################

  @spec flow_view(t(), GtBridge.Phlow.Builder) :: Mondrian.t()
  defview flow_view(self = %__MODULE__{}, builder) do
    items = self.controllers ++ self.contexts ++ self.event_types ++ self.ets_tables
    by_id = Map.new(items, &{node_id(&1), &1})

    builder.mondrian()
    |> Mondrian.title("Flow")
    |> Mondrian.priority(1)
    |> Mondrian.nodes(items)
    |> Mondrian.node_label(&node_label/1)
    |> Mondrian.edges(fn item ->
      self.graph
      |> Graph.out_neighbors(node_id(item))
      |> Enum.map(&Map.get(by_id, &1))
      |> Enum.reject(&is_nil/1)
    end)
    |> Mondrian.layout(:horizontal_tree)
  end

  @spec lint_view(t(), GtBridge.Phlow.Builder) :: Text.t()
  defview lint_view(self = %__MODULE__{}, builder) do
    body = """
    Orphan ETS tables (write-only):
      #{Enum.map_join(orphan_ets(self), ", ", &Atom.to_string(&1.name)) |> blank_to_dash()}

    Orphan contexts (no HTTP entry):
      #{Enum.map_join(orphan_contexts(self), ", ", & &1.label) |> blank_to_dash()}
    """

    builder.text() |> Text.title("Lint") |> Text.priority(2) |> Text.string(fn -> body end)
  end

  ############################################################
  #                     Per-Kind Views                       #
  ############################################################

  defview controller_routes_view(self = %Controller{}, builder) do
    builder.columned_list()
    |> ColumnedList.title("Routes")
    |> ColumnedList.priority(1)
    |> ColumnedList.items(fn -> self.routes end)
    |> ColumnedList.column("Route", & &1)
  end

  defview controller_calls_view(self = %Controller{}, builder) do
    builder.columned_list()
    |> ColumnedList.title("Calls")
    |> ColumnedList.priority(2)
    |> ColumnedList.items(fn -> self.calls end)
    |> ColumnedList.column("Context", &inspect/1)
  end

  defview context_summary_view(self = %Context{}, builder) do
    body = """
    Module:        #{inspect(self.module)}
    Called by:     #{Enum.map_join(self.inbound, ", ", &inspect/1) |> blank_to_dash()}
    Produces:      #{Enum.join(self.produces, ", ") |> blank_to_dash()}
    Reads tables:  #{Enum.map_join(self.reads, ", ", &Atom.to_string/1) |> blank_to_dash()}
    """

    builder.text() |> Text.title("Summary") |> Text.priority(1) |> Text.string(fn -> body end)
  end

  defview event_type_blast_radius_view(self = %EventType{}, builder) do
    nodes =
      Enum.map(self.producers, &%{kind: :producer, label: short(&1)}) ++
        [%{kind: :event, label: self.name}] ++
        Enum.map(self.writes, fn {tab, op} -> %{kind: :table, label: "#{tab} (#{op})"} end) ++
        Enum.map(self.downstream_readers, &%{kind: :reader, label: short(&1)})

    table_set = MapSet.new(self.writes, fn {t, _} -> t end)

    edges_fn = fn item ->
      cond do
        item.kind == :producer ->
          [Enum.find(nodes, &(&1.kind == :event))]

        item.kind == :event ->
          Enum.filter(nodes, &(&1.kind == :table))

        item.kind == :table ->
          tab = item.label |> String.split(" ") |> hd() |> String.to_atom()

          if MapSet.member?(table_set, tab),
            do: Enum.filter(nodes, &(&1.kind == :reader)),
            else: []

        true ->
          []
      end
    end

    builder.mondrian()
    |> Mondrian.title("Blast Radius")
    |> Mondrian.priority(1)
    |> Mondrian.nodes(nodes)
    |> Mondrian.node_label(& &1.label)
    |> Mondrian.edges(edges_fn)
    |> Mondrian.layout(:horizontal_tree)
  end

  defview event_type_summary_view(self = %EventType{}, builder) do
    body = """
    Event:           #{self.name}
    Produced by:     #{Enum.map_join(self.producers, ", ", &inspect/1) |> blank_to_dash()}
    Writes:          #{Enum.map_join(self.writes, ", ", fn {t, op} -> "#{t} (#{op})" end) |> blank_to_dash()}
    Read downstream: #{Enum.map_join(self.downstream_readers, ", ", &inspect/1) |> blank_to_dash()}
    Total in log:    #{self.count || "n/a"}
    """

    builder.text() |> Text.title("Summary") |> Text.priority(2) |> Text.string(fn -> body end)
  end

  defview ets_table_io_view(self = %EtsTable{}, builder) do
    body = """
    Table:        #{self.name}
    Size now:     #{self.size || "n/a"}
    Written by:   #{Enum.join(self.written_by, ", ") |> blank_to_dash()}
    Read by:      #{Enum.map_join(self.read_by, ", ", &inspect/1) |> blank_to_dash()}
    """

    builder.text() |> Text.title("I/O") |> Text.priority(1) |> Text.string(fn -> body end)
  end

  ############################################################
  #                      Node Builders                       #
  ############################################################

  defp build_controllers(mods, routes, calls_per_ctrl) do
    routes_by = Enum.group_by(routes, & &1.plug)

    Enum.map(mods, fn mod ->
      route_strs =
        routes_by
        |> Map.get(mod, [])
        |> Enum.map(fn r ->
          "#{r.verb |> Atom.to_string() |> String.upcase()} #{r.path} → #{r.plug_opts}"
        end)

      %Controller{
        module: mod,
        label: short(mod),
        routes: route_strs,
        calls: Map.get(calls_per_ctrl, mod, [])
      }
    end)
  end

  defp build_contexts(modules, calls_per_ctrl, appends_per_ctx, reader_calls, reader_map) do
    inbound_by =
      calls_per_ctrl
      |> Enum.flat_map(fn {ctrl, ctxs} -> Enum.map(ctxs, &{&1, ctrl}) end)
      |> Enum.group_by(fn {ctx, _} -> ctx end, fn {_, ctrl} -> ctrl end)

    Enum.map(modules, fn mod ->
      reads =
        reader_calls
        |> Map.get(mod, [])
        |> Enum.map(&Map.fetch!(reader_map, &1))
        |> Enum.uniq()

      %Context{
        module: mod,
        label: short(mod),
        inbound: Map.get(inbound_by, mod, []) |> Enum.uniq(),
        produces: Map.get(appends_per_ctx, mod, []),
        reads: reads
      }
    end)
  end

  defp build_event_types(
         event_types,
         appends_per_ctx,
         writes_per_event,
         reader_calls,
         reader_map
       ) do
    producers_by =
      appends_per_ctx
      |> Enum.flat_map(fn {ctx, types} -> Enum.map(types, &{&1, ctx}) end)
      |> Enum.group_by(fn {t, _} -> t end, fn {_, ctx} -> ctx end)

    Enum.map(event_types, fn t ->
      writes = Map.get(writes_per_event, t, []) |> Enum.uniq()
      written_tables = MapSet.new(writes, fn {tab, _} -> tab end)

      downstream =
        reader_calls
        |> Enum.flat_map(fn {ctx, funs} ->
          if Enum.any?(funs, &MapSet.member?(written_tables, Map.fetch!(reader_map, &1))),
            do: [ctx],
            else: []
        end)
        |> Enum.uniq()

      %EventType{
        name: t,
        producers: Map.get(producers_by, t, []),
        writes: writes,
        downstream_readers: downstream,
        count: runtime_event_count(t)
      }
    end)
  end

  defp build_ets_tables(ets_attrs, writes_per_event, reader_calls, reader_map) do
    written_by_tab =
      writes_per_event
      |> Enum.flat_map(fn {type, ops} -> Enum.map(ops, fn {tab, _} -> {tab, type} end) end)
      |> Enum.group_by(fn {tab, _} -> tab end, fn {_, type} -> type end)

    read_by_tab =
      reader_calls
      |> Enum.flat_map(fn {ctx, funs} -> Enum.map(funs, &{Map.fetch!(reader_map, &1), ctx}) end)
      |> Enum.group_by(fn {tab, _} -> tab end, fn {_, ctx} -> ctx end)

    Enum.map(ets_attrs, fn {_attr, tab} ->
      %EtsTable{
        name: tab,
        written_by: Map.get(written_by_tab, tab, []) |> Enum.uniq(),
        read_by: Map.get(read_by_tab, tab, []) |> Enum.uniq(),
        size: runtime_ets_size(tab)
      }
    end)
  end

  ############################################################
  #                      Graph Builder                       #
  ############################################################

  defp build_graph(controllers, contexts, event_types, ets_tables) do
    g = Graph.new()

    g =
      Enum.reduce(controllers ++ contexts ++ event_types ++ ets_tables, g, fn n, acc ->
        Graph.add_vertex(acc, node_id(n), n)
      end)

    g
    |> add_call_edges(controllers)
    |> add_produces_edges(contexts)
    |> add_writes_edges(event_types)
    |> add_reads_edges(ets_tables)
  end

  defp add_call_edges(g, controllers) do
    Enum.reduce(controllers, g, fn c, acc ->
      Enum.reduce(c.calls, acc, fn ctx_mod, acc2 ->
        Graph.add_edge(acc2, "controller:#{c.label}", "context:#{short(ctx_mod)}", label: :call)
      end)
    end)
  end

  defp add_produces_edges(g, contexts) do
    Enum.reduce(contexts, g, fn c, acc ->
      Enum.reduce(c.produces, acc, fn t, acc2 ->
        Graph.add_edge(acc2, "context:#{c.label}", "event_type:#{t}", label: :produces)
      end)
    end)
  end

  defp add_writes_edges(g, event_types) do
    Enum.reduce(event_types, g, fn et, acc ->
      Enum.reduce(et.writes, acc, fn {tab, op}, acc2 ->
        Graph.add_edge(acc2, "event_type:#{et.name}", "ets:#{tab}", label: {:writes, op})
      end)
    end)
  end

  defp add_reads_edges(g, ets_tables) do
    Enum.reduce(ets_tables, g, fn tab, acc ->
      Enum.reduce(tab.read_by, acc, fn ctx_mod, acc2 ->
        Graph.add_edge(acc2, "ets:#{tab.name}", "context:#{short(ctx_mod)}", label: :reads)
      end)
    end)
  end

  ############################################################
  #                  Xref + Filter Helpers                   #
  ############################################################

  defp contexts_calling(hub) do
    hub |> Analysis.callers(@app) |> Enum.filter(&context_module?/1)
  end

  defp ctrl_calls(ctrl, ctx_set) do
    ctrl
    |> Analysis.callees(@app)
    |> Enum.filter(&MapSet.member?(ctx_set, &1))
    |> Enum.uniq()
  end

  defp context_module?(mod) do
    parts = Module.split(mod)

    hd(parts) == "LocalUpload" and length(parts) == 2 and
      mod not in [@projection_module, @event_store, LocalUpload.Repo, __MODULE__]
  end

  ############################################################
  #                  AST Literal Extraction                  #
  ############################################################

  defp ets_attrs(module) do
    module
    |> module_ast()
    |> collect_nodes(fn
      {:@, _, [{name, _, [value]}]} when is_atom(name) and is_atom(value) ->
        if String.starts_with?(Atom.to_string(value), "local_upload_"),
          do: {:ok, {name, value}},
          else: :skip

      _ ->
        :skip
    end)
    |> Map.new()
  end

  defp event_types(module) do
    module
    |> module_ast()
    |> collect_nodes(fn
      {:type, value} when is_binary(value) -> {:ok, value}
      _ -> :skip
    end)
    |> Enum.uniq()
  end

  defp event_store_appends(module) do
    module
    |> module_ast()
    |> collect_nodes(fn
      {{:., _, [{:__aliases__, _, aliases}, :append]}, _, [{:%{}, _, kw}]} ->
        if List.last(aliases) == :EventStore do
          case Keyword.get(kw, :type) do
            t when is_binary(t) -> {:ok, t}
            _ -> :skip
          end
        else
          :skip
        end

      _ ->
        :skip
    end)
  end

  defp projection_reader_calls(module, reader_funs) do
    module
    |> module_ast()
    |> collect_nodes(fn
      {{:., _, [{:__aliases__, _, aliases}, fun]}, _, _} when is_atom(fun) ->
        if List.last(aliases) == :ProjectionStore and fun in reader_funs,
          do: {:ok, fun},
          else: :skip

      _ ->
        :skip
    end)
  end

  defp module_ast(module) do
    path = module.module_info(:compile) |> Keyword.fetch!(:source) |> to_string()
    {:ok, ast} = path |> File.read!() |> Code.string_to_quoted()
    ast
  end

  defp collect_nodes(ast, matcher) do
    {_, acc} =
      Macro.prewalk(ast, [], fn node, acc ->
        case matcher.(node) do
          {:ok, value} -> {node, [value | acc]}
          :skip -> {node, acc}
        end
      end)

    Enum.reverse(acc)
  end

  ############################################################
  #                      Runtime Probes                      #
  ############################################################

  defp runtime_ets_size(tab) do
    case :ets.info(tab, :size) do
      :undefined -> nil
      n -> n
    end
  end

  defp runtime_event_count(type) do
    import Ecto.Query

    try do
      LocalUpload.EventStore.Event
      |> where([e], e.type == ^type)
      |> select([e], count(e.id))
      |> LocalUpload.Repo.one()
    rescue
      _ -> nil
    end
  end

  ############################################################
  #                          Misc                            #
  ############################################################

  defp short(mod), do: Module.split(mod) |> List.last()
  defp blank_to_dash(""), do: "—"
  defp blank_to_dash(s), do: s

  defp node_id(%Controller{label: l}), do: "controller:#{l}"
  defp node_id(%Context{label: l}), do: "context:#{l}"
  defp node_id(%EventType{name: n}), do: "event_type:#{n}"
  defp node_id(%EtsTable{name: n}), do: "ets:#{n}"

  defp node_label(%Controller{label: l}), do: l
  defp node_label(%Context{label: l}), do: l
  defp node_label(%EventType{name: n}), do: n
  defp node_label(%EtsTable{name: n}), do: Atom.to_string(n)
end
