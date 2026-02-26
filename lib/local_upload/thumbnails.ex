defmodule LocalUpload.Thumbnails do
  @moduledoc """
  I generate thumbnails for image and video uploads via ffmpeg.
  I append a `thumbnail_generated` event on success, which the
  ProjectionStore uses to set `thumb_name` on the upload.
  """

  alias LocalUpload.Uploads
  alias LocalUpload.Uploads.Upload
  alias LocalUpload.EventStore

  @doc "I generate a thumbnail for the given upload if its content type is thumbable."
  @spec generate(Upload.t()) :: :ok | :not_thumbable
  def generate(%Upload{} = upload) do
    if thumbable?(upload.content_type) do
      do_generate(upload)
    else
      :not_thumbable
    end
  end

  @doc "I compute the thumbnail filename for a stored name."
  @spec thumb_name_for(String.t()) :: String.t()
  def thumb_name_for(stored_name),
    do: "th_" <> Path.rootname(stored_name) <> ".jpg"

  @doc "I return true if the content type can be thumbnailed."
  @spec thumbable?(String.t()) :: boolean()
  def thumbable?(content_type) do
    String.starts_with?(content_type, "image/") or
      String.starts_with?(content_type, "video/")
  end

  @spec do_generate(Upload.t()) :: :ok
  defp do_generate(%Upload{} = upload) do
    case System.find_executable("ffmpeg") do
      nil ->
        :ok

      ffmpeg ->
        src = Uploads.file_path(upload.stored_name)
        thumb = thumb_name_for(upload.stored_name)
        dest = Uploads.file_path(thumb)

        case System.cmd(ffmpeg, [
               "-i",
               src,
               "-vframes",
               "1",
               "-vf",
               "scale=200:200:force_original_aspect_ratio=decrease",
               "-y",
               dest
             ]) do
          {_, 0} ->
            {:ok, _} =
              EventStore.append(%{
                type: "thumbnail_generated",
                data: %{
                  "stored_name" => upload.stored_name,
                  "thumb_name" => thumb
                }
              })

            :ok

          {_, _} ->
            :ok
        end
    end
  end
end
