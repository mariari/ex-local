defmodule LocalUpload.Uploads.PomfResponse do
  @moduledoc """
  I am the PomfResponse struct. I represent the JSON body returned
  by the pomf upload API.
  """

  use TypedStruct

  @type file_entry :: %{
          hash: String.t(),
          name: String.t(),
          url: String.t(),
          size: integer()
        }

  typedstruct do
    field :success, boolean(), enforce: true
    field :files, [file_entry()], default: []
    field :errorcode, integer()
    field :description, String.t()
  end

  @doc "I build a successful pomf response from a list of file entries."
  @spec success([file_entry()]) :: t()
  def success(files), do: %__MODULE__{success: true, files: files}

  @doc "I build an error pomf response."
  @spec error(integer(), String.t()) :: t()
  def error(code, desc) do
    %__MODULE__{
      success: false,
      errorcode: code,
      description: desc
    }
  end

  @doc "I convert a pomf response to a JSON-serializable map."
  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{success: true} = r) do
    %{"success" => true, "files" => r.files}
  end

  def to_json(%__MODULE__{success: false} = r) do
    %{
      "success" => false,
      "errorcode" => r.errorcode,
      "description" => r.description
    }
  end
end
