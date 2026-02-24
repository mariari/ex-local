defmodule LocalUpload.Uploads.Upload do
  @moduledoc "I am the Upload struct. I represent a file stored on disk."

  use TypedStruct

  typedstruct do
    field :stored_name, String.t(), enforce: true
    field :original_name, String.t(), enforce: true
    field :hash, String.t(), enforce: true
    field :size, integer(), enforce: true
    field :content_type, String.t(), enforce: true
    field :uploader, String.t(), default: "anonymous"
    field :vote_count, integer(), default: 0
    field :inserted_at, DateTime.t()
  end

  @doc "I build an Upload from event data."
  @spec new(map()) :: t()
  def new(data) do
    %__MODULE__{
      stored_name: data["stored_name"],
      original_name: data["original_name"],
      hash: data["hash"],
      size: data["size"],
      content_type: data["content_type"],
      uploader: data["uploader"] || "anonymous",
      inserted_at: DateTime.utc_now()
    }
  end
end
