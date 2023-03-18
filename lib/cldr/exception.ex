defmodule Cldr.PersonNameError do
  @moduledoc """
  Exception raised when person name formatting.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end
