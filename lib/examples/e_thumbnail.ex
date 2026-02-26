defmodule EThumbnail do
  @moduledoc """
  I demonstrate thumbnail generation for image and video uploads.
  I show that ffmpeg produces a thumbnail file on disk and the
  projection records its name.
  """

  use ExExample
  import ExUnit.Assertions

  alias LocalUpload.Uploads
  alias LocalUpload.Uploads.Upload
  alias LocalUpload.Thumbnails

  @spec generate_thumbnail() :: Upload.t()
  example generate_thumbnail do
    path = Path.join(System.tmp_dir!(), "thumb_test.gif")
    File.write!(path, gif_1x1())

    plug_upload = %Plug.Upload{
      path: path,
      filename: "thumb_test.gif",
      content_type: "image/gif"
    }

    {:ok, upload} = Uploads.store_file(plug_upload, "thumber")

    # Re-fetch to get thumb_name set by the thumbnail_generated event
    updated = Uploads.get!(upload.stored_name)

    if System.find_executable("ffmpeg") do
      assert updated.thumb_name != nil
      assert File.exists?(Uploads.file_path(updated.thumb_name))
    end

    updated
  end

  @spec skip_non_image() :: :not_thumbable
  example skip_non_image do
    path = Path.join(System.tmp_dir!(), "thumb_test.txt")
    File.write!(path, "just text, no thumbnail")

    plug_upload = %Plug.Upload{
      path: path,
      filename: "thumb_test.txt",
      content_type: "text/plain"
    }

    {:ok, upload} = Uploads.store_file(plug_upload, "thumber")
    result = Thumbnails.generate(upload)
    assert result == :not_thumbable

    result
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
