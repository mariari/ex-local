defmodule LocalUpload.Repo.Migrations.CreateUploads do
  use Ecto.Migration

  def change do
    create table(:uploads) do
      add :original_name, :string, null: false
      add :stored_name, :string, null: false
      add :hash, :string, null: false
      add :size, :integer, null: false
      add :content_type, :string, null: false
      add :uploader, :string, null: false, default: "anonymous"
      add :vote_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:uploads, [:stored_name])
    create index(:uploads, [:hash])
    create index(:uploads, [:inserted_at])
  end
end
