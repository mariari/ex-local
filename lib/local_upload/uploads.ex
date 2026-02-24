defmodule LocalUpload.Uploads do
  @moduledoc """
  I am the Uploads context. I handle file storage and upload record
  management. I am the essential logic layer for uploads — all
  derived views over the uploads relation live here.
  """

  import Ecto.Query
  alias LocalUpload.Repo
  alias LocalUpload.Uploads.Upload
  alias LocalUpload.EventStore

  ############################################################
  #                        Public API                        #
  ############################################################

  @doc """
  I store a file from a Plug.Upload and create a DB record.

  If a file with the same SHA-1 hash already exists, I return
  the existing upload instead of storing a duplicate.
  """
  @spec store_file(Plug.Upload.t(), String.t()) ::
          {:ok, Upload.t()} | {:error, Ecto.Changeset.t() | File.posix()}
  def store_file(%Plug.Upload{} = plug_upload, uploader \\ "anonymous") do
    hash = compute_hash(plug_upload.path)

    case Upload |> where(hash: ^hash) |> limit(1) |> Repo.one() do
      %Upload{} = existing ->
        {:ok, existing}

      nil ->
        store_new_file(plug_upload, hash, uploader)
    end
  end

  @doc "I find an upload by its stored filename."
  @spec get_by_stored_name(String.t()) :: Upload.t() | nil
  def get_by_stored_name(name) do
    Repo.get_by(Upload, stored_name: name)
  end

  @doc "I fetch an upload by ID, raising if not found."
  @spec get!(integer()) :: Upload.t()
  def get!(id), do: Repo.get!(Upload, id)

  @doc "I return the top voted uploads from the last 7 days."
  @spec top_of_week(integer()) :: [Upload.t()]
  def top_of_week(limit \\ 10) do
    week_ago = DateTime.add(DateTime.utc_now(), -7, :day)

    Upload
    |> where([u], u.inserted_at >= ^week_ago)
    |> order_by([u], desc: u.vote_count)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc "I return the most recently uploaded files."
  @spec list_recent(integer()) :: [Upload.t()]
  def list_recent(limit \\ 50) do
    Upload
    |> order_by([u], desc: u.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc "I return the full filesystem path for a stored filename."
  @spec file_path(String.t()) :: String.t()
  def file_path(stored_name) do
    Path.join(upload_dir(), stored_name)
  end

  @doc "I return the configured upload directory."
  @spec upload_dir() :: String.t()
  def upload_dir do
    Application.get_env(:local_upload, :upload_dir, "priv/uploads")
  end

  ############################################################
  #                   Private Implementation                 #
  ############################################################

  @spec store_new_file(Plug.Upload.t(), String.t(), String.t()) ::
          {:ok, Upload.t()} | {:error, Ecto.Changeset.t() | File.posix()}
  defp store_new_file(plug_upload, hash, uploader) do
    stored_name = generate_stored_name(plug_upload.filename)
    dest = file_path(stored_name)
    size = File.stat!(plug_upload.path).size

    with :ok <- File.cp(plug_upload.path, dest) do
      case EventStore.append(%{
             type: "file_uploaded",
             data: %{
               "original_name" => plug_upload.filename,
               "stored_name" => stored_name,
               "hash" => hash,
               "size" => size,
               "content_type" => plug_upload.content_type || "application/octet-stream",
               "uploader" => uploader
             }
           }) do
        {:ok, {_event, upload}} -> {:ok, upload}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  @spec generate_stored_name(String.t()) :: String.t()
  defp generate_stored_name(original_name) do
    ext = Path.extname(original_name)

    slug =
      :crypto.strong_rand_bytes(4)
      |> Base.url_encode64(padding: false)

    slug <> ext
  end

  @spec compute_hash(Path.t()) :: String.t()
  defp compute_hash(path) do
    File.stream!(path, 2048)
    |> Enum.reduce(
      :crypto.hash_init(:sha),
      &:crypto.hash_update(&2, &1)
    )
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  end
end
