defmodule LocalUploadWeb.AdminHTML do
  @moduledoc """
  I contain pages rendered by AdminController.

  See the `admin_html` directory for all templates available.
  """
  use LocalUploadWeb, :html

  import LocalUploadWeb.Helpers

  embed_templates "admin_html/*"

  @spec file_icon(String.t()) :: String.t()
  defp file_icon(content_type) do
    cond do
      String.starts_with?(content_type, "video/") -> "\u25B6"
      String.starts_with?(content_type, "audio/") -> "\u266B"
      String.starts_with?(content_type, "text/") -> "\u{1F4C4}"
      true -> "\u{1F4CE}"
    end
  end
end
