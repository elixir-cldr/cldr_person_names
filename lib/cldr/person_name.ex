defmodule Cldr.PersonName do
  @moduledoc """
  Cldr module to formats person names.

  """

  import Kernel, except: [to_string: 1]
  alias Cldr.PersonName.Formatter

  @doc "Return the title as a string or nil for the given struct"
  @callback title(name :: struct()) :: String.t() | nil

  @doc "Return the given name as a stringor nil for the given struct"
  @callback given_name(name :: struct()) :: String.t() | nil

  @doc "Return the informal given name as a string or nil for the given struct"
  @callback informal_given_name(name :: struct()) :: String.t() | nil

  @doc "Return the other given names as a string or nil for the given struct"
  @callback other_given_names(name :: struct()) :: String.t() | nil

  @doc "Return the surname prefix as a string or nil for the given struct"
  @callback surname_prefix(name :: struct()) :: String.t() | nil

  @doc "Return the surname as a string or nil for the given struct"
  @callback surname(name :: struct()) :: String.t() | nil

  @doc "Return the other surnames as a string or nil for the given struct"
  @callback other_surnames(name :: struct()) :: String.t() | nil

  @doc "Return the generation as a string or nil for the given struct"
  @callback generation(name :: struct()) :: String.t() | nil

  @doc "Return the credentials as a string or nil for the given struct"
  @callback credentials(name :: struct()) :: String.t() | nil

  @doc "Return the locale reference or nil for the given struct"
  @callback locale(name :: struct()) :: Cldr.Locale.locale_reference() | nil

  @doc "Return the other preferred name order for the given struct"
  @callback preferred_order(name :: struct()) :: Formatter.name_order()

  @person_name [
    title: nil,
    given_name: nil,
    other_given_names: nil,
    informal_given_name: nil,
    surname_prefix: nil,
    surname: nil,
    other_surnames: nil,
    generation: nil,
    credentials: nil,
    preferred_order: nil,
    locale: nil
  ]

  defstruct @person_name

  @typedoc """
  A PersonName struct containing the fields supported
  for person name formatting.  Any struct that implements
  the `#{inspect __MODULE__}` behaviour can be converted
  to this struct by calling `Cldr.PersonName.cast_to_person_name/1`.

  """
  @type t :: %__MODULE__{
    title: String.t() | nil,
    given_name: String.t() | nil,
    other_given_names: String.t() | nil,
    informal_given_name: String.t() | nil,
    surname_prefix: String.t() | nil,
    surname: String.t() | nil,
    other_surnames: String.t() | nil,
    generation: String.t() | nil,
    credentials: String.t() | nil,
    preferred_order: Formatter.name_order() | nil,
    locale: Cldr.Locale.locale_reference()
  }

  @type error_message() :: String.t() | {module(), String.t()}

  @spec new(options :: Keyword.t()) :: {:ok, t()} | {:error, error_message()}
  def new(options \\ []) do
    with {:ok, validated} <- validate_name(options) do
      {:ok, struct(__MODULE__, validated)}
    end
  end

  @spec to_string(name :: struct(), options :: Formatter.format_options()) ::
    {:ok, String.t()} | {:error, error_message()}

  def to_string(name, options \\ []) when is_struct(name) do
    with {:ok, iodata} <- to_iodata(name, options) do
      {:ok, :erlang.iolist_to_binary(iodata)}
    end
  end

  @spec to_string(name :: struct(), options :: Formatter.format_options()) ::
    String.t() | no_return()

  def to_string!(name, options \\ []) when is_struct(name) do
    case to_string(name, options) do
      {:ok, formatted_name} -> formatted_name
      {:error, reason} -> raise_error(reason)
    end
  end

  @spec to_iodata(name :: struct(), options :: Formatter.format_options()) ::
    {:ok, :erlang.iodata()} | {:error, error_message()}

  def to_iodata(name, options \\ []) when is_struct(name) do
    {locale, backend} = Cldr.locale_and_backend_from(options)

    with {:ok, name} <- maybe_cast_name(name),
         {:ok, name} <- validate_name(name),
         {:ok, formatting_locale} <- Cldr.validate_locale(locale, backend) do
      Formatter.to_iodata(name, formatting_locale, backend, options)
    end
  end

  @spec to_iodata!(name :: struct(), options :: Formatter.format_options()) ::
    :erlang.iodata() | no_return()

  def to_iodata!(name, options \\ []) when is_struct(name) do
    case to_iodata(name, options) do
      {:ok, iodata} -> iodata
      {:error, reason} -> raise_error(reason)
    end
  end

  defimpl Cldr.PersonName.Format, for: __MODULE__ do
    @moduledoc """
    Implements the Cldr.PersonName.Chars protocol for
    the `t:Cldr.PersonName.t/0` struct.

    """
    def to_string(name, options) do
      Cldr.PersonName.to_string(name, options)
    end

    def to_string!(name, options) do
      Cldr.PersonName.to_string(name, options)
    end
  end

  @doc """
  Casts any struct that implements the `#{inspect __MODULE__}`
  behaviour into a `t:Cldr.PersonName.t/0` struct.

  """
  @spec cast_to_person_name(struct()) :: t()
  def cast_to_person_name(%module{}) do
    %__MODULE__{
      title: module.title(),
      given_name: module.given_name(),
      other_given_names: module.other_given_names(),
      informal_given_name: module.other_given_name(),
      surname_prefix: module.surname_prefix(),
      surname: module.surname(),
      other_surnames: module.other_surnames(),
      generation: module.generation(),
      credentials: module.credentials(),
      preferred_order: module.preferred_order(),
      locale: module.locale()
    }
  end

  @behaviour __MODULE__

  @impl Cldr.PersonName
  def title(%__MODULE__{title: title}),
    do: title

  @impl Cldr.PersonName
  def given_name(%__MODULE__{given_name: given_name}),
    do: given_name

  @impl Cldr.PersonName
  def other_given_names(%__MODULE__{other_given_names: other_given_names}),
    do: other_given_names

  @impl Cldr.PersonName
  def informal_given_name(%__MODULE__{informal_given_name: informal_given_name}),
    do: informal_given_name

  @impl Cldr.PersonName
  def surname_prefix(%__MODULE__{surname_prefix: surname_prefix}),
    do: surname_prefix

  @impl Cldr.PersonName
  def surname(%__MODULE__{surname: surname}),
    do: surname

  @impl Cldr.PersonName
  def other_surnames(%__MODULE__{other_surnames: other_surnames}),
    do: other_surnames

  @impl Cldr.PersonName
  def generation(%__MODULE__{generation: generation}),
    do: generation

  @impl Cldr.PersonName
  def credentials(%__MODULE__{credentials: credentials}),
    do: credentials

  @impl Cldr.PersonName
  def locale(%__MODULE__{locale: locale}),
    do: locale

  @impl Cldr.PersonName
  def preferred_order(%__MODULE__{preferred_order: preferred_order}),
    do: preferred_order

  defp maybe_cast_name(%__MODULE__{} = name) do
    {:ok, name}
  end

  defp maybe_cast_name(%module{} = name) when module != __MODULE__ do
    name
    |> cast_to_person_name()
    |> Formatter.wrap(:ok)
  end

  # A name needs only a given name to be minimally viable.
  defp validate_name(%{given_name: given_name} = name) when is_binary(given_name) do
    {:ok, name}
  end

  defp validate_name(name) do
    {:error, "Name requires at least a :given_name. Found #{inspect(name)}"}
  end

  defp raise_error(reason) when is_binary(reason) do
    raise Cldr.PersonNameError, reason
  end

  defp raise_error({exception, message}) do
    raise exception, message
  end
end
