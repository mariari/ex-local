defmodule EPomfResponse do
  @moduledoc """
  I demonstrate building pomf JSON responses from uploads.
  I build on EUpload.

  ## Example

      iex> json = EPomfResponse.example()
      iex> json["success"]
      true
  """

  import ExUnit.Assertions
  alias LocalUpload.Uploads.PomfResponse

  @doc "I create an upload and serialize it to pomf JSON format."
  @spec example() :: map()
  def example do
    upload = EUpload.create_example()

    file_entry = %{
      hash: upload.hash,
      name: upload.original_name,
      url: "http://localhost:4000/f/#{upload.stored_name}",
      size: upload.size
    }

    response = PomfResponse.success([file_entry])
    json = PomfResponse.to_json(response)

    assert json["success"] == true
    assert length(json["files"]) == 1

    [file] = json["files"]
    assert file.name == "test_vomit.txt"
    assert String.contains?(file.url, "/f/")

    json
  end

  @doc "I demonstrate an error response."
  @spec error_example() :: map()
  def error_example do
    response = PomfResponse.error(400, "No input file(s)")
    json = PomfResponse.to_json(response)

    assert json["success"] == false
    assert json["errorcode"] == 400
    assert json["description"] == "No input file(s)"

    json
  end
end
