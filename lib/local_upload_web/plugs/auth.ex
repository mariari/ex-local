defmodule LocalUploadWeb.Plugs.Auth do
  @moduledoc """
  I am the Auth plug. I set `conn.assigns.authenticated?` based on
  whether the session has been authenticated with the upload secret.
  """

  import Plug.Conn

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, _opts) do
    assign(conn, :authenticated?, get_session(conn, :authenticated) == true)
  end
end
