defmodule LocalUploadWeb.Helpers do
  @moduledoc "I provide shared formatting helpers for templates."

  @doc "I format a byte count into a human-readable string."
  @spec format_bytes(integer()) :: String.t()
  def format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"

  def format_bytes(bytes) when bytes < 1_048_576 do
    "#{Float.round(bytes / 1024, 1)} KB"
  end

  def format_bytes(bytes) do
    "#{Float.round(bytes / 1_048_576, 1)} MB"
  end

  @doc "I return the uploader name for display: real name for admins, truncated hash for visitors."
  @spec display_uploader(String.t(), boolean()) :: String.t()
  def display_uploader(name, true), do: name

  def display_uploader(name, false) do
    :crypto.hash(:sha256, name)
    |> Base.encode16(case: :lower)
    |> binary_part(0, 8)
  end
end
