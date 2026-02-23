defmodule LocalUpload.Uploads.Upload do
  @moduledoc "I am the Upload schema. I represent a file stored on disk."

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          original_name: String.t(),
          stored_name: String.t(),
          hash: String.t(),
          size: integer(),
          content_type: String.t(),
          uploader: String.t(),
          vote_count: integer(),
          comments:
            [LocalUpload.Comments.Comment.t()]
            | Ecto.Association.NotLoaded.t(),
          votes:
            [LocalUpload.Votes.Vote.t()]
            | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "uploads" do
    field :original_name, :string
    field :stored_name, :string
    field :hash, :string
    field :size, :integer
    field :content_type, :string
    field :uploader, :string, default: "anonymous"
    field :vote_count, :integer, default: 0

    has_many :comments, LocalUpload.Comments.Comment
    has_many :votes, LocalUpload.Votes.Vote

    timestamps(type: :utc_datetime)
  end

  @doc "I build a changeset for creating an upload record."
  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [
      :original_name,
      :stored_name,
      :hash,
      :size,
      :content_type,
      :uploader
    ])
    |> validate_required([
      :original_name,
      :stored_name,
      :hash,
      :size,
      :content_type
    ])
    |> unique_constraint(:stored_name)
  end
end
