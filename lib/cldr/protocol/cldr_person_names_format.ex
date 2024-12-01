defprotocol Cldr.PersonName.Format do
  alias Cldr.PersonName
  alias Cldr.PersonName.Formatter

  @spec to_string(name :: struct(), options :: Formatter.format_options()) ::
          {:ok, String.t()} | {:error, PersonName.error_message()}

  def to_string(name, options \\ [])

  @spec to_string(name :: struct(), options :: Formatter.format_options()) ::
          String.t() | no_return()

  def to_string!(name, options \\ [])
end
