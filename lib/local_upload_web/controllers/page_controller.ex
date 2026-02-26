defmodule LocalUploadWeb.PageController do
  @moduledoc """
  I am the PageController. I render the homepage with the top
  vomited files of the week.
  """

  use LocalUploadWeb, :controller

  alias LocalUpload.Uploads

  def home(conn, _params) do
    top_uploads = Uploads.top_of_week(10)
    recent_uploads = Uploads.list_recent(50)
    render(conn, :home, top_uploads: top_uploads, recent_uploads: recent_uploads)
  end
end
