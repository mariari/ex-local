defmodule LocalUpload.Repo.Migrations.CreateVotes do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :upload_id, references(:uploads, on_delete: :delete_all),
        null: false

      add :ip_hash, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:votes, [:upload_id, :ip_hash],
      name: :votes_upload_ip_unique
    )

    create index(:votes, [:inserted_at])
  end
end
