defmodule LocalUpload.Votes.Vote do
  @moduledoc "I am the Vote schema. I represent a thumbs-up on an upload."

  use Ecto.Schema

  @type t :: %__MODULE__{
          id: integer() | nil,
          ip_hash: String.t(),
          upload_id: integer(),
          upload:
            LocalUpload.Uploads.Upload.t()
            | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "votes" do
    field :ip_hash, :string

    belongs_to :upload, LocalUpload.Uploads.Upload

    timestamps(type: :utc_datetime)
  end
end
