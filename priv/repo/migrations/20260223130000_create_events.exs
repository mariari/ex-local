defmodule LocalUpload.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :type, :string, null: false
      add :data, :map, null: false
      add :aggregate_id, :integer

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:events, [:type])
    create index(:events, [:aggregate_id])
    create index(:events, [:inserted_at])
  end
end
