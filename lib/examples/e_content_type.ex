defmodule EContentType do
  @moduledoc """
  I demonstrate content type detection from magic bytes.
  I show that the system overrides client-claimed MIME types
  when the file signature tells a different story.
  """

  use ExExample
  import ExUnit.Assertions

  alias LocalUpload.ContentType
  alias LocalUpload.Uploads

  @spec detect_gif() :: String.t()
  example detect_gif do
    path = Path.join(System.tmp_dir!(), "magic_test.gif")
    File.write!(path, gif_bytes())
    result = ContentType.detect(path)
    assert result == "image/gif"
    result
  end

  @spec detect_jpeg() :: String.t()
  example detect_jpeg do
    path = Path.join(System.tmp_dir!(), "magic_test.jpg")
    File.write!(path, <<0xFF, 0xD8, 0xFF, 0xE0, 0::unit(8)-size(12)>>)
    result = ContentType.detect(path)
    assert result == "image/jpeg"
    result
  end

  @spec detect_png() :: String.t()
  example detect_png do
    path = Path.join(System.tmp_dir!(), "magic_test.png")
    File.write!(path, <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0::unit(8)-size(8)>>)
    result = ContentType.detect(path)
    assert result == "image/png"
    result
  end

  @spec fallback_for_unknown() :: String.t()
  example fallback_for_unknown do
    path = Path.join(System.tmp_dir!(), "magic_test.bin")
    File.write!(path, :crypto.strong_rand_bytes(16))
    result = ContentType.detect(path, "application/octet-stream")
    assert result == "application/octet-stream"
    result
  end

  @spec override_in_upload() :: Uploads.Upload.t()
  example override_in_upload do
    path = Path.join(System.tmp_dir!(), "lying_gif.bin")
    File.write!(path, gif_bytes())

    plug_upload = %Plug.Upload{
      path: path,
      filename: "lying_gif.bin",
      content_type: "text/plain"
    }

    {:ok, upload} = Uploads.store_file(plug_upload, "tester")
    assert upload.content_type == "image/gif"
    upload
  end

  # 1x1 GIF with red pixel (distinct hash from e_upload's white GIF)
  defp gif_bytes do
    <<0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00, 0x00, 0xFF, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x02,
      0x02, 0x44, 0x01, 0x00, 0x3B>>
  end

  @spec rerun?(any()) :: boolean()
  def rerun?(_), do: false
end
