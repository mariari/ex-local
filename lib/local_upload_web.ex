defmodule LocalUploadWeb do
  @moduledoc "I am the web entrypoint. I define macros for controllers and HTML modules."

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: LocalUploadWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      unquote(html_helpers())
    end
  end

  @spec html_helpers() :: Macro.t()
  defp html_helpers do
    quote do
      use Gettext, backend: LocalUploadWeb.Gettext

      import Phoenix.HTML
      import LocalUploadWeb.CoreComponents

      alias LocalUploadWeb.Layouts

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: LocalUploadWeb.Endpoint,
        router: LocalUploadWeb.Router,
        statics: LocalUploadWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/html.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
