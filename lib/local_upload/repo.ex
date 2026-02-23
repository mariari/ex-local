defmodule LocalUpload.Repo do
  use Ecto.Repo,
    otp_app: :local_upload,
    adapter: Ecto.Adapters.SQLite3
end
