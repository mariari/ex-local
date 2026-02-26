defmodule EAdmin do
  @moduledoc """
  I demonstrate the admin dashboard. I show that unauthenticated
  requests are rejected and authenticated requests see stats.
  """

  use ExExample
  import ExUnit.Assertions
  import Phoenix.ConnTest, only: [build_conn: 0]

  @endpoint LocalUploadWeb.Endpoint

  @spec admin_rejects_unauthenticated() :: Plug.Conn.t()
  example admin_rejects_unauthenticated do
    conn =
      build_conn()
      |> Phoenix.ConnTest.get("/admin")

    assert conn.status == 403
    assert conn.resp_body =~ "Forbidden"

    conn
  end

  @spec admin_shows_stats() :: Plug.Conn.t()
  example admin_shows_stats do
    _upload = EUpload.create_upload()

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{authenticated: true})
      |> Phoenix.ConnTest.get("/admin")

    assert conn.status == 200
    assert conn.resp_body =~ "Admin Dashboard"
    assert conn.resp_body =~ "Total Files"
    assert conn.resp_body =~ "Disk Usage"

    conn
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
