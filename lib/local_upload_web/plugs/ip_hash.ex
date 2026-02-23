defmodule LocalUploadWeb.Plugs.IPHash do
  @moduledoc """
  I am the IPHash plug. I compute a truncated SHA-256 hash of the
  client IP address and assign it to `conn.assigns.ip_hash`.
  """

  import Plug.Conn

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, _opts) do
    hash =
      conn.remote_ip
      |> :inet.ntoa()
      |> to_string()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 16)

    assign(conn, :ip_hash, hash)
  end
end
