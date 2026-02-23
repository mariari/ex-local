defmodule LocalUpload.EventStore.Event do
  @moduledoc "I am an immutable fact. I record something that happened."

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          type: String.t() | nil,
          data: map() | nil,
          aggregate_id: integer() | nil,
          inserted_at: DateTime.t() | nil
        }

  schema "events" do
    field :type, :string
    field :data, :map
    field :aggregate_id, :integer

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @spec changeset(t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:type, :data, :aggregate_id])
    |> validate_required([:type, :data])
  end
end
