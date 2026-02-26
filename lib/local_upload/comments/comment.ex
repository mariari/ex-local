defmodule LocalUpload.Comments.Comment do
  @moduledoc """
  I am the Comment struct. I represent an anonymous comment on an
  uploaded file.
  """

  use TypedStruct
  use GtBridge.View

  alias GtBridge.Phlow.ColumnedList
  alias GtBridge.Phlow.Text

  typedstruct do
    field :stored_name, String.t(), enforce: true
    field :body, String.t(), enforce: true
    field :author_name, String.t(), default: "Anonymous"
    field :ip_hash, String.t(), enforce: true
    field :mono_id, integer(), enforce: true
    field :inserted_at, DateTime.t()
  end

  @doc "I build a Comment from event data. mono_id is the event's DB id."
  @spec new(map(), integer(), DateTime.t()) :: t()
  def new(data, event_id, inserted_at) do
    %__MODULE__{
      stored_name: data["stored_name"],
      body: data["body"],
      author_name: data["author_name"] || "Anonymous",
      ip_hash: data["ip_hash"],
      mono_id: event_id,
      inserted_at: inserted_at
    }
  end

  ############################################################
  #                        GT Views                          #
  ############################################################

  @spec comment_view(t(), GtBridge.Phlow.Builder) :: Text.t()
  defview comment_view(self = %__MODULE__{}, builder) do
    builder.text()
    |> Text.title("Comment")
    |> Text.priority(1)
    |> Text.string(fn ->
      "#{self.author_name} at #{self.inserted_at}:\n\n#{self.body}"
    end)
  end

  @spec fields_view(t(), GtBridge.Phlow.Builder) :: ColumnedList.t()
  defview fields_view(self = %__MODULE__{}, builder) do
    fields = [
      {"stored_name", self.stored_name},
      {"body", self.body},
      {"author_name", self.author_name},
      {"ip_hash", self.ip_hash},
      {"mono_id", self.mono_id},
      {"inserted_at", to_string(self.inserted_at)}
    ]

    builder.columned_list()
    |> ColumnedList.title("Fields")
    |> ColumnedList.priority(2)
    |> ColumnedList.items(fn -> fields end)
    |> ColumnedList.column("Name", fn {k, _v} -> k end)
    |> ColumnedList.column("Value", fn {_k, v} -> to_string(v) end)
  end
end
