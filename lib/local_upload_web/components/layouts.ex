defmodule LocalUploadWeb.Layouts do
  @moduledoc "I hold the root layout and flash group component."

  use LocalUploadWeb, :html

  embed_templates "layouts/*"

  @doc "I render info and error flash notices together."
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end
end
