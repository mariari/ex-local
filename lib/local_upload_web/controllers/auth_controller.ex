defmodule LocalUploadWeb.AuthController do
  @moduledoc """
  I am the AuthController. I handle session-based authentication
  using the shared upload secret.
  """

  use LocalUploadWeb, :controller

  @doc "I render the login form."
  def new(conn, _params) do
    render(conn, :new)
  end

  @doc "I validate the secret and set the session."
  def create(conn, %{"secret" => secret}) do
    case check_secret(secret) do
      :ok ->
        conn
        |> put_session(:authenticated, true)
        |> put_flash(:info, "Authenticated.")
        |> redirect(to: ~p"/")

      :unauthorized ->
        conn
        |> put_flash(:error, "Invalid secret.")
        |> redirect(to: ~p"/auth")
    end
  end

  @doc "I clear the session."
  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Logged out.")
    |> redirect(to: ~p"/")
  end

  @spec check_secret(String.t()) :: :ok | :unauthorized
  defp check_secret(secret) do
    case Application.get_env(:local_upload, :upload_secret) do
      nil -> :ok
      expected -> if secret == expected, do: :ok, else: :unauthorized
    end
  end
end
