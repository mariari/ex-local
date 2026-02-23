defmodule LocalUpload.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :upload_id, references(:uploads, on_delete: :delete_all),
        null: false

      add :body, :text, null: false
      add :author_name, :string, default: "Anonymous"
      add :ip_hash, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:upload_id])
  end
end
