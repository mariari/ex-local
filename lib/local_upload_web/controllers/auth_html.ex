defmodule LocalUploadWeb.AuthHTML do
  @moduledoc """
  I contain pages rendered by AuthController.

  See the `auth_html` directory for all templates available.
  """
  use LocalUploadWeb, :html

  embed_templates "auth_html/*"
end
