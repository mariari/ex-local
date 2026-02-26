defmodule LocalUpload.ContentType do
  @moduledoc """
  I detect content types from file magic bytes. I read the first
  16 bytes of a file and match against known signatures, overriding
  unreliable client-provided MIME types.
  """

  @doc """
  I detect the content type of a file at `path` by reading its
  magic bytes. I return the detected type, or `fallback` if the
  signature is unrecognized.
  """
  @spec detect(Path.t(), String.t()) :: String.t()
  def detect(path, fallback \\ "application/octet-stream") do
    case :file.open(path, [:read, :binary]) do
      {:ok, fd} ->
        result = :file.read(fd, 16)
        :file.close(fd)

        case result do
          {:ok, bytes} -> detect_bytes(bytes) || fallback
          :eof -> fallback
        end

      {:error, _} ->
        fallback
    end
  end

  @spec detect_bytes(binary()) :: String.t() | nil
  defp detect_bytes(<<0xFF, 0xD8, 0xFF, _::binary>>), do: "image/jpeg"

  defp detect_bytes(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>),
    do: "image/png"

  defp detect_bytes(<<0x47, 0x49, 0x46, 0x38, _::binary>>), do: "image/gif"
  defp detect_bytes(<<"RIFF", _size::32, "WEBP", _::binary>>), do: "image/webp"
  defp detect_bytes(<<0x25, 0x50, 0x44, 0x46, _::binary>>), do: "application/pdf"
  defp detect_bytes(<<_skip::32, "ftyp", _::binary>>), do: "video/mp4"
  defp detect_bytes(<<0x1A, 0x45, 0xDF, 0xA3, _::binary>>), do: "video/webm"
  defp detect_bytes(<<"RIFF", _size::32, "AVI ", _::binary>>), do: "video/x-msvideo"
  defp detect_bytes(<<"OggS", _::binary>>), do: "application/ogg"
  defp detect_bytes(<<"fLaC", _::binary>>), do: "audio/flac"
  defp detect_bytes(<<"ID3", _::binary>>), do: "audio/mpeg"
  defp detect_bytes(<<0xFF, 0xFB, _::binary>>), do: "audio/mpeg"
  defp detect_bytes(<<0xFF, 0xF3, _::binary>>), do: "audio/mpeg"
  defp detect_bytes(<<0xFF, 0xF2, _::binary>>), do: "audio/mpeg"
  defp detect_bytes(<<"RIFF", _size::32, "WAVE", _::binary>>), do: "audio/wav"
  defp detect_bytes(<<"BM", _::binary>>), do: "image/bmp"
  defp detect_bytes(<<0x50, 0x4B, 0x03, 0x04, _::binary>>), do: "application/zip"
  defp detect_bytes(_), do: nil
end
