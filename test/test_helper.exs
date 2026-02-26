ExUnit.start()
:ok = Ecto.Adapters.SQL.Sandbox.checkout(LocalUpload.Repo)
Ecto.Adapters.SQL.Sandbox.mode(LocalUpload.Repo, {:shared, self()})
