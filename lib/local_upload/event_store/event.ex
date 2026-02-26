defmodule LocalUpload.EventStore.Event do
  @moduledoc "I am an immutable fact. I record something that happened."

  use Ecto.Schema
  use GtBridge.View

  import Ecto.Changeset

  alias GtBridge.Phlow.ColumnedList
  alias GtBridge.Phlow.Text

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

  ############################################################
  #                        GT Views                          #
  ############################################################

  @spec event_view(t(), GtBridge.Phlow.Builder) :: Text.t()
  defview event_view(self = %__MODULE__{}, builder) do
    builder.text()
    |> Text.title("Event")
    |> Text.priority(1)
    |> Text.string(fn ->
      data_str =
        self.data
        |> Enum.map_join("\n  ", fn {k, v} -> "#{k}: #{inspect(v)}" end)

      "[#{self.type}] at #{self.inserted_at}\n  #{data_str}"
    end)
  end

  @spec data_view(t(), GtBridge.Phlow.Builder) :: ColumnedList.t()
  defview data_view(self = %__MODULE__{}, builder) do
    builder.columned_list()
    |> ColumnedList.title("Data")
    |> ColumnedList.priority(2)
    |> ColumnedList.items(fn -> Enum.to_list(self.data || %{}) end)
    |> ColumnedList.column("Key", fn {k, _v} -> to_string(k) end)
    |> ColumnedList.column("Value", fn {_k, v} -> inspect(v) end)
  end
end
