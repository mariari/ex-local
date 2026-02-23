defmodule LocalUploadWeb.UploadHTML do
  @moduledoc """
  I contain pages rendered by UploadController.

  See the `upload_html` directory for all templates available.
  """
  use LocalUploadWeb, :html

  embed_templates "upload_html/*"

  @doc "I format a byte count into a human-readable string."
  def format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"

  def format_bytes(bytes) when bytes < 1_048_576 do
    "#{Float.round(bytes / 1024, 1)} KB"
  end

  def format_bytes(bytes) do
    "#{Float.round(bytes / 1_048_576, 1)} MB"
  end
end
