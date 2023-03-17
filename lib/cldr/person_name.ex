defmodule Cldr.PersonName do
  @moduledoc """
  Cldr module to formats person names.

  """

  @person_name [
    locale: nil,
    prefix: "",
    title: "",
    given_name: "",
    other_given_names: "",
    given_informal: "",
    surname: "",
    other_surnames: "",
    generation: "",
    credentials: "",
    preferred_order: :given_first
  ]

  defstruct @person_name

  defdelegate cldr_backend_provider(config), to: Cldr.PersonName.Backend, as: :define_backend_module

  def new(options \\ []) do
    with {:ok, validated} <- validate_name(options) do
      {:ok, struct(__MODULE__, validated)}
    end
  end

  def to_string(%__MODULE__{} = _name, options \\ []) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
  end

  defp validate_name(options) do
    options
  end
end
