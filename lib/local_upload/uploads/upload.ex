defmodule LocalUpload.Uploads.Upload do
  @moduledoc "I am the Upload struct. I represent a file stored on disk."

  use TypedStruct
  use GtBridge.View

  alias GtBridge.Phlow.ColumnedList
  alias GtBridge.Phlow.Text
  alias LocalUpload.ProjectionStore
  alias LocalUploadWeb.Helpers

  typedstruct do
    field :stored_name, String.t(), enforce: true
    field :original_name, String.t(), enforce: true
    field :hash, String.t(), enforce: true
    field :size, integer(), enforce: true
    field :content_type, String.t(), enforce: true
    field :uploader, String.t(), default: "anonymous"
    field :vote_count, integer(), default: 0
    field :thumb_name, String.t()
    field :inserted_at, DateTime.t()
  end

  @doc "I build an Upload from event data, using the event's timestamp."
  @spec new(map(), DateTime.t()) :: t()
  def new(data, inserted_at) do
    %__MODULE__{
      stored_name: data["stored_name"],
      original_name: data["original_name"],
      hash: data["hash"],
      size: data["size"],
      content_type: data["content_type"],
      uploader: data["uploader"] || "anonymous",
      inserted_at: inserted_at
    }
  end

  ############################################################
  #                        GT Views                          #
  ############################################################

  @spec details_view(t(), GtBridge.Phlow.Builder) :: Text.t()
  defview details_view(self = %__MODULE__{}, builder) do
    builder.text()
    |> Text.title("Details")
    |> Text.priority(1)
    |> Text.string(fn ->
      """
      Name:         #{self.original_name}
      Stored as:    #{self.stored_name}
      Size:         #{Helpers.format_bytes(self.size)}
      Content-Type: #{self.content_type}
      Uploader:     #{self.uploader}
      Hash:         #{String.slice(self.hash, 0, 12)}...
      Uploaded at:  #{self.inserted_at}
      Votes:        #{self.vote_count}
      Thumbnail:    #{self.thumb_name || "none"}\
      """
    end)
  end

  @spec fields_view(t(), GtBridge.Phlow.Builder) :: ColumnedList.t()
  defview fields_view(self = %__MODULE__{}, builder) do
    fields = [
      {"stored_name", self.stored_name},
      {"original_name", self.original_name},
      {"hash", self.hash},
      {"size", Helpers.format_bytes(self.size)},
      {"content_type", self.content_type},
      {"uploader", self.uploader},
      {"vote_count", self.vote_count},
      {"thumb_name", self.thumb_name || "none"},
      {"inserted_at", to_string(self.inserted_at)}
    ]

    builder.columned_list()
    |> ColumnedList.title("Fields")
    |> ColumnedList.priority(2)
    |> ColumnedList.items(fn -> fields end)
    |> ColumnedList.column("Name", fn {k, _v} -> k end)
    |> ColumnedList.column("Value", fn {_k, v} -> to_string(v) end)
  end

  @spec comments_view(t(), GtBridge.Phlow.Builder) :: ColumnedList.t()
  defview comments_view(self = %__MODULE__{}, builder) do
    builder.columned_list()
    |> ColumnedList.title("Comments")
    |> ColumnedList.priority(3)
    |> ColumnedList.items(fn ->
      ProjectionStore.list_comments(self.stored_name)
    end)
    |> ColumnedList.column("Author", fn c -> c.author_name end)
    |> ColumnedList.column("Body", fn c -> c.body end)
    |> ColumnedList.column("Time", fn c -> to_string(c.inserted_at) end)
  end
end
