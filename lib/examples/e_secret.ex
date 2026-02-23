defmodule ESecret do
  @moduledoc """
  I demonstrate the shared secret upload protection.
  I temporarily set and clear the upload_secret config to verify
  that the PomfController rejects and accepts requests correctly.
  """

  use ExExample
  import ExUnit.Assertions
  import Phoenix.ConnTest, only: [build_conn: 0]
  import Plug.Conn, only: [put_req_header: 3]

  @endpoint LocalUploadWeb.Endpoint

  @spec secret_rejects_bad_request() :: map()
  example secret_rejects_bad_request do
    Application.put_env(:local_upload, :upload_secret, "s3cret")

    conn =
      build_conn()
      |> put_req_header("content-type", "multipart/form-data")
      |> Phoenix.ConnTest.post("/upload.php", %{"files" => [], "secret" => "wrong"})

    json = Phoenix.json_library().decode!(conn.resp_body)
    assert conn.status == 403
    assert json["success"] == false
    assert json["description"] == "Invalid secret"

    Application.put_env(:local_upload, :upload_secret, nil)

    json
  end

  @spec secret_accepts_good_request() :: map()
  example secret_accepts_good_request do
    Application.put_env(:local_upload, :upload_secret, "s3cret")

    path = Path.join(System.tmp_dir!(), "secret_test.txt")
    File.write!(path, "secret vomit")

    upload = %Plug.Upload{
      path: path,
      filename: "secret_test.txt",
      content_type: "text/plain"
    }

    conn =
      build_conn()
      |> put_req_header("content-type", "multipart/form-data")
      |> Phoenix.ConnTest.post("/upload.php", %{
        "files" => [upload],
        "secret" => "s3cret"
      })

    json = Phoenix.json_library().decode!(conn.resp_body)
    assert conn.status == 200
    assert json["success"] == true
    assert length(json["files"]) == 1

    Application.put_env(:local_upload, :upload_secret, nil)

    json
  end

  @spec open_when_no_secret() :: map()
  example open_when_no_secret do
    # ensure no secret is configured
    Application.put_env(:local_upload, :upload_secret, nil)

    path = Path.join(System.tmp_dir!(), "open_test.txt")
    File.write!(path, "open vomit")

    upload = %Plug.Upload{
      path: path,
      filename: "open_test.txt",
      content_type: "text/plain"
    }

    conn =
      build_conn()
      |> put_req_header("content-type", "multipart/form-data")
      |> Phoenix.ConnTest.post("/upload.php", %{"files" => [upload]})

    json = Phoenix.json_library().decode!(conn.resp_body)
    assert conn.status == 200
    assert json["success"] == true

    json
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
