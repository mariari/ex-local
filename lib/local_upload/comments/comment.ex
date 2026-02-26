defmodule LocalUpload.Comments.Comment do
  @moduledoc """
  I am the Comment struct. I represent an anonymous comment on an
  uploaded file.
  """

  use TypedStruct

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
end
