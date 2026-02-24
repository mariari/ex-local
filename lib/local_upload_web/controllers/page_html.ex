defmodule LocalUploadWeb.PageHTML do
  @moduledoc """
  I contain pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use LocalUploadWeb, :html

  import LocalUploadWeb.Helpers

  embed_templates "page_html/*"
end
