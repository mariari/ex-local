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
    assert found.stored_name == upload.stored_name
    found
  end

  @spec dedup_upload() :: Upload.t()
  example dedup_upload do
    upload = create_upload()

    # uploading the same content again returns the existing record
    path = Path.join(System.tmp_dir!(), "test_vomit_dup.txt")
    File.write!(path, "hello from vomitchan!")

    dup = %Plug.Upload{
      path: path,
      filename: "different_name.txt",
      content_type: "text/plain"
    }

    {:ok, found} = Uploads.store_file(dup, "someone_else")
    assert found.stored_name == upload.stored_name

    found
  end

  @spec create_image_upload() :: Upload.t()
  example create_image_upload do
    path = Path.join(System.tmp_dir!(), "test_vomit.gif")
    File.write!(path, gif_1x1())

    plug_upload = %Plug.Upload{
      path: path,
      filename: "test_vomit.gif",
      content_type: "image/gif"
    }

    {:ok, upload} = Uploads.store_file(plug_upload, "mariari")

    assert upload.content_type == "image/gif"
    assert String.ends_with?(upload.stored_name, ".gif")
    assert File.exists?(Uploads.file_path(upload.stored_name))

    upload
  end

  @spec list_recent_uploads() :: [Upload.t()]
  example list_recent_uploads do
    _upload = create_upload()
    recent = Uploads.list_recent(5)
    assert length(recent) > 0
    recent
  end

  # Valid 1x1 white pixel GIF89a (35 bytes)
  defp gif_1x1 do
    <<0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00, 0x00, 0xFF, 0xFF,
      0xFF, 0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x02,
      0x02, 0x44, 0x01, 0x00, 0x3B>>
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
