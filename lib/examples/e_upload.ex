defmodule EUpload do
  @moduledoc """
  I am the foundation example for uploads. I demonstrate storing
  a file and retrieving it from the database.

  All other examples build on me.
  """

  import ExUnit.Assertions
  alias LocalUpload.Uploads

  @doc """
  I create a temporary file, store it via the Uploads context,
  and return the upload record.

  ## Example

      iex> upload = EUpload.create_example()
      iex> upload.original_name
      "test_vomit.txt"
  """
  @spec create_example() :: LocalUpload.Uploads.Upload.t()
  def create_example do
    # Create a temp file with some content
    path = Path.join(System.tmp_dir!(), "test_vomit.txt")
    File.write!(path, "hello from vomitchan!")

    plug_upload = %Plug.Upload{
      path: path,
      filename: "test_vomit.txt",
      content_type: "text/plain"
    }

    {:ok, upload} = Uploads.store_file(plug_upload, "mariari")

    # Verify it was stored
    assert upload.original_name == "test_vomit.txt"
    assert upload.uploader == "mariari"
    assert upload.size == byte_size("hello from vomitchan!")
    assert upload.vote_count == 0

    # Verify the file exists on disk
    assert File.exists?(Uploads.file_path(upload.stored_name))

    # Verify we can retrieve it from DB
    found = Uploads.get_by_stored_name(upload.stored_name)
    assert found.id == upload.id

    upload
  end

  @doc """
  I create multiple uploads to seed the system for other examples.
  I return a list of upload records.
  """
  @spec seed_examples(integer()) :: [LocalUpload.Uploads.Upload.t()]
  def seed_examples(count \\ 3) do
    Enum.map(1..count, fn i ->
      path = Path.join(System.tmp_dir!(), "vomit_#{i}.txt")
      File.write!(path, "vomit content #{i}")

      plug_upload = %Plug.Upload{
        path: path,
        filename: "vomit_#{i}.txt",
        content_type: "text/plain"
      }

      {:ok, upload} = Uploads.store_file(plug_upload, "user_#{i}")
      upload
    end)
  end
end
