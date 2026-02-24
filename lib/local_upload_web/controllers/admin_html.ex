defmodule LocalUploadWeb.AdminHTML do
  @moduledoc """
  I contain pages rendered by AdminController.

  See the `admin_html` directory for all templates available.
  """
  use LocalUploadWeb, :html

  embed_templates "admin_html/*"

  @doc "I format a byte count into a human-readable string."
  @spec format_bytes(integer()) :: String.t()
  def format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"

  def format_bytes(bytes) when bytes < 1_048_576 do
    "#{Float.round(bytes / 1024, 1)} KB"
  end

  def format_bytes(bytes) do
    "#{Float.round(bytes / 1_048_576, 1)} MB"
  end

  @doc "I return true if the upload has an image content type."
  @spec image?(map()) :: boolean()
  def image?(%{content_type: ct}), do: String.starts_with?(ct || "", "image/")

  @doc "I return true if the upload has a video content type."
  @spec video?(map()) :: boolean()
  def video?(%{content_type: ct}), do: String.starts_with?(ct || "", "video/")
end
