defmodule LocalUploadWeb.UploadHTML do
  @moduledoc """
  I contain pages rendered by UploadController.

  See the `upload_html` directory for all templates available.
  """
  use LocalUploadWeb, :html

  import LocalUploadWeb.Helpers

  embed_templates "upload_html/*"
end
