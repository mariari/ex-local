defmodule LocalUploadWeb.PageController do
  use LocalUploadWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
