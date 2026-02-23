defmodule LocalUpload.Comments.Comment do
  @moduledoc """
  I am the Comment schema. I represent an anonymous comment on an
  uploaded file.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          body: String.t(),
          author_name: String.t(),
          ip_hash: String.t(),
          upload_id: integer(),
          upload:
            LocalUpload.Uploads.Upload.t()
            | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "comments" do
    field :body, :string
    field :author_name, :string, default: "Anonymous"
    field :ip_hash, :string

    belongs_to :upload, LocalUpload.Uploads.Upload

    timestamps(type: :utc_datetime)
  end

  @doc "I build a changeset for creating a comment."
  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :author_name, :upload_id, :ip_hash])
    |> validate_required([:body, :upload_id, :ip_hash])
    |> validate_length(:body, min: 1, max: 5000)
    |> foreign_key_constraint(:upload_id)
  end
end
