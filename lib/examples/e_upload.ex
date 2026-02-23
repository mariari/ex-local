defmodule EUpload do
  @moduledoc """
  I am the foundation example for uploads. I demonstrate storing
  a file and retrieving it from the database.

  All other examples build on me.
  """

  use ExExample
  import ExUnit.Assertions

  alias LocalUpload.Uploads
  alias LocalUpload.Uploads.Upload

  @spec create_upload() :: Upload.t()
  example create_upload do
    path = Path.join(System.tmp_dir!(), "test_vomit.txt")
    File.write!(path, "hello from vomitchan!")

    plug_upload = %Plug.Upload{
      path: path,
      filename: "test_vomit.txt",
      content_type: "text/plain"
    }

    {:ok, upload} = Uploads.store_file(plug_upload, "mariari")

    assert upload.original_name == "test_vomit.txt"
    assert upload.uploader == "mariari"
    assert upload.size == byte_size("hello from vomitchan!")
    assert upload.vote_count == 0
    assert File.exists?(Uploads.file_path(upload.stored_name))

    upload
  end

  @spec retrieve_upload() :: Upload.t()
  example retrieve_upload do
    upload = create_upload()
    found = Uploads.get_by_stored_name(upload.stored_name)
    assert found.id == upload.id
    found
  end

  @spec list_recent_uploads() :: [Upload.t()]
  example list_recent_uploads do
    _upload = create_upload()
    recent = Uploads.list_recent(5)
    assert length(recent) > 0
    recent
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
