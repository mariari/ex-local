defmodule LocalUpload.Repo.Migrations.DropProjectionTables do
  use Ecto.Migration

  def change do
    drop_if_exists table(:votes)
    drop_if_exists table(:comments)
    drop_if_exists table(:uploads)
  end
end
