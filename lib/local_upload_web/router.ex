defmodule LocalUploadWeb.Router do
  use LocalUploadWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LocalUploadWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug LocalUploadWeb.Plugs.IPHash
  end

  pipeline :pomf_api do
    plug :accepts, ["json"]
  end

  # Pomf-compatible upload API (no CSRF — stateless bot protocol)
  scope "/", LocalUploadWeb do
    pipe_through :pomf_api

    post "/upload.php", PomfController, :upload
  end

  # File serving (outside pipelines — just sends bytes)
  scope "/f", LocalUploadWeb do
    get "/:name", FileController, :show
  end

  # Web UI
  scope "/", LocalUploadWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/browse", UploadController, :index
    get "/uploads/:stored_name", UploadController, :show
    post "/uploads/:stored_name/comments", CommentController, :create
    post "/uploads/:stored_name/vote", VoteController, :create
  end
end
