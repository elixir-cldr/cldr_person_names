defmodule Cldr.PersonName do
  @readme Path.expand("README.md")
  @external_resource @readme
  @moduledoc @readme |> File.read!() |> String.split("<!-- Split --->") |> List.last() |> String.trim()

  import Kernel, except: [to_string: 1]
  alias Cldr.PersonName.Formatter

  @doc "Return the title as a `t:String.t/0` or `nil` for the given struct"
  @callback title(name :: struct()) :: String.t() | nil

  @doc "Return the given name as a `t:String.t/0` or `nil` for the given struct"
  @callback given_name(name :: struct()) :: String.t() | nil

  @doc "Return the informal given name as a `t:String.t/0` or `nil` for the given struct"
  @callback informal_given_name(name :: struct()) :: String.t() | nil

  @doc "Return the other given names as a `t:String.t/0` or `nil` for the given struct"
  @callback other_given_names(name :: struct()) :: String.t() | nil

  @doc "Return the surname prefix as a `t:String.t/0` or `nil` for the given struct"
  @callback surname_prefix(name :: struct()) :: String.t() | nil

  @doc "Return the surname as a `t:String.t/0` or `nil` for the given struct"
  @callback surname(name :: struct()) :: String.t() | nil

  @doc "Return the other surnames as a `t:String.t/0` or `nil` for the given struct"
  @callback other_surnames(name :: struct()) :: String.t() | nil

  @doc "Return the generation as a `t:String.t/0` or `nil` for the given struct"
  @callback generation(name :: struct()) :: String.t() | nil

  @doc "Return the credentials as a `t:String.t/0` or `nil` for the given struct"
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

  @typedoc "Standard error response"
  @type error_message() :: String.t() | {module(), String.t()}

  @doc """
  Returns a `t:Cldr.PersonName.t/0` struct crafted
  from a keyword list of attributes.

  ### Arguments

  * `attributes` is a keyword list of person name
    attributes that is used to contruct a `t:Cldr.PersonName.t/0`.

  ### Attributes

  * `:given_name` is a persons given name. This is a required
    attribute. The value is any `t:String.t/0`

  * `:title` is a person's title such as "Mr," or "Dr.".

  * `:other_given_names` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:informal_given_name` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:surname_prefix` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:surname` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:other_surnames` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:generation` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:credentials` is any `t:String.t/0` or `nil`. The
    default is `nil`.

  * `:locale` is any `t:Cldr.LanguageTag.t/0` or nil. The
    default is `nil`.

  * `:backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`. This is used to validate the `:locale`
    only. The default is `Cldr.default_backend!/0`.

  * `:name_order` is one of `:given_name`, `:last_name` or
    `:sorting`. The default is `nil`, meaning that the name order
    is derived from the name's locale and the formatting locale.

  ### Returns

  * `{:ok, person_name_struct}` or

  * `{:error, reason}`

  ### Examples

        iex> Cldr.PersonName.new(title: "Mr.", given_name: "José", surname: "Valim", credentials: "Ph.D.", locale: "pt")
        {:ok,
         %Cldr.PersonName{
           title: "Mr.",
           given_name: "José",
           other_given_names: nil,
           informal_given_name: nil,
           surname_prefix: nil,
           surname: "Valim",
           other_surnames: nil,
           generation: nil,
           credentials: "Ph.D.",
           preferred_order: nil,
           locale: AllBackend.Cldr.Locale.new!("pt")
         }}

        iex> Cldr.PersonName.new(surname: "Valim")
        {:error, "Person Name requires at least a :given_name"}

  """

  @spec new(attributes :: Keyword.t()) :: {:ok, t()} | {:error, error_message()}
  def new(attributes \\ []) do
    validate_name(attributes)
  end

  @doc """
  Returns a formatted person name as an
  `:erlang.iodata` term.

  ### Arguments

  * `person_name` is any struct that implements the
    `Cldr.PersonName` behaviour, including the native
    `t:Cldr.PersonName.t/0` struct.

  * `options` is a keyword list of options.

  ### Options

  * `:format` is the relative length of a formatted name
    depending on context. For example, a long formal
    name in English might include `:title`, `:given_name`,
    `:other_given_names`, `:surname` plus `:generation` and
    `:credentials`; whereas a short informal name may only be
    the `:given_name`. The valid values are `:short`, `:medium`
    and `:long`. The default is derived from the formatting
    locales preferences.

  * `:usage` indicates if the formatted name is being used
    to address someone, refer to someone, or present their
    name in an abbreviated form. The valid values are`:referring`,
    `:addressing` or `:monogram`. The default is `:referring`. The pattern
    for `:referring` may be the same as the pattern for
    `:addressing`.

  * `:formality` indicates the formality of usage. A name on a
    badge for an informal gathering may be much different
    from an award announcement at the Nobel Prize Ceremonies. The
    valid values are `:formal` and `:informal`. Note that the
    formats may be the same for different formality scenarios
    depending on the length, usage, and cultural conventions
    for the locale. For example short formal and short
    informal may both be just the given name. The default is
    derived from the formatting locale preferences.

  * `:order` is used express preference for the orders of attributes
    in the formatted string. The valid values are `:given_first`,
    `:surname_first` and `:sorting`. The default is based on features
    of the person name struct and the formatting locale. The
    option `:sorting` is only every defined as an option - not the
    person name or locale data.

  ### Notes

  The formats may be the same for different lengths
  depending on the formality, usage, and cultural conventions
  for the locale.

  For example, medium and short may be the same for a
  particular context.

  ### Returns

  * `{:ok, formatted_name}` or

  * `{:error, reason}`.

  ### Examples

      iex> {:ok, jose} = Cldr.PersonName.new(title: "Mr.", given_name: "José", surname: "Valim",
      ...> credentials: "Ph.D.", locale: "pt")
      iex> Cldr.PersonName.to_string(jose)
      {:ok, "José"}
      iex> Cldr.PersonName.to_string(jose, format: :long)
      {:ok, "José"}
      iex> Cldr.PersonName.to_string(jose, format: :long, formality: :formal)
      {:ok, "Mr. Valim"}
      iex> Cldr.PersonName.to_string(jose, format: :long, formality: :formal, usage: :referring)
      {:ok, "Mr. José Valim, Ph.D."}

  """
  @spec to_string(name :: struct(), options :: Formatter.format_options()) ::
    {:ok, String.t()} | {:error, error_message()}

  def to_string(name, options \\ []) when is_struct(name) do
    with {:ok, iodata} <- to_iodata(name, options) do
      {:ok, :erlang.iolist_to_binary(iodata)}
    end
  end

  @doc """
  Returns a formatted person name as an
  `:erlang.iodata` term.

  ### Arguments

  * `person_name` is any struct that implements the
    `Cldr.PersonName` behaviour, including the native
    `t:Cldr.PersonName.t/0` struct.

  * `options` is a keyword list of options.

  ### Options

  * `:format` is the relative length of a formatted name
    depending on context. For example, a long formal
    name in English might include `:title`, `:given_name`,
    `:other_given_names`, `:surname` plus `:generation` and
    `:credentials`; whereas a short informal name may only be
    the `:given_name`. The valid values are `:short`, `:medium`
    and `:long`. The default is derived from the formatting
    locales preferences.

  * `:usage` indicates if the formatted name is being used
    to address someone, refer to someone, or present their
    name in an abbreviated form. The valid values are`:referring`,
    `:addressing` or `:monogram`. The default is `:referring`. The pattern
    for `:referring` may be the same as the pattern for
    `:addressing`.

  * `:formality` indicates the formality of usage. A name on a
    badge for an informal gathering may be much different
    from an award announcement at the Nobel Prize Ceremonies. The
    valid values are `:formal` and `:informal`. Note that the
    formats may be the same for different formality scenarios
    depending on the length, usage, and cultural conventions
    for the locale. For example short formal and short
    informal may both be just the given name. The default is
    derived from the formatting locale preferences.

  * `:order` is used express preference for the orders of attributes
    in the formatted string. The valid values are `:given_first`,
    `:surname_first` and `:sorting`. The default is based on features
    of the person name struct and the formatting locale. The
    option `:sorting` is only every defined as an option - not the
    person name or locale data.

  ### Notes

  The formats may be the same for different lengths
  depending on the formality, usage, and cultural conventions
  for the locale.

  For example, medium and short may be the same for a
  particular context.

  ### Returns

  * `{:ok, formatted_name}` or

  * `{:error, reason}`.

  ### Examples

      iex> {:ok, jose} = Cldr.PersonName.new(title: "Mr.", given_name: "José", surname: "Valim", credentials: "Ph.D.", locale: "pt")
      iex> Cldr.PersonName.to_string!(jose)
      "José"
      iex> Cldr.PersonName.to_string!(jose, format: :long)
      "José"
      iex> Cldr.PersonName.to_string!(jose, format: :long, formality: :formal)
      "Mr. Valim"
      iex> Cldr.PersonName.to_string!(jose, format: :long, formality: :formal, usage: :referring)
      "Mr. José Valim, Ph.D."

  """

  @spec to_string!(name :: struct(), options :: Formatter.format_options()) ::
    String.t() | no_return()

  def to_string!(name, options \\ []) when is_struct(name) do
    case to_string(name, options) do
      {:ok, formatted_name} -> formatted_name
      {:error, reason} -> raise_error(reason)
    end
  end

  @doc """
  Returns a formatted person name as an
  `:erlang.iodata` term.

  ### Arguments

  * `person_name` is any struct that implements the
    `Cldr.PersonName` behaviour, including the native
    `t:Cldr.PersonName.t/0` struct.

  * `options` is a keyword list of options.

  ### Options

  * `:format` is the relative length of a formatted name
    depending on context. For example, a long formal
    name in English might include `:title`, `:given_name`,
    `:other_given_names`, `:surname` plus `:generation` and
    `:credentials`; whereas a short informal name may only be
    the `:given_name`. The valid values are `:short`, `:medium`
    and `:long`. The default is derived from the formatting
    locales preferences.

  * `:usage` indicates if the formatted name is being used
    to address someone, refer to someone, or present their
    name in an abbreviated form. The valid values are`:referring`,
    `:addressing` or `:monogram`. The default is `:referring`. The pattern
    for `:referring` may be the same as the pattern for
    `:addressing`.

  * `:formality` indicates the formality of usage. A name on a
    badge for an informal gathering may be much different
    from an award announcement at the Nobel Prize Ceremonies. The
    valid values are `:formal` and `:informal`. Note that the
    formats may be the same for different formality scenarios
    depending on the length, usage, and cultural conventions
    for the locale. For example short formal and short
    informal may both be just the given name. The default is
    derived from the formatting locale preferences.

  * `:order` is used express preference for the orders of attributes
    in the formatted string. The valid values are `:given_first`,
    `:surname_first` and `:sorting`. The default is based on features
    of the person name struct and the formatting locale. The
    option `:sorting` is only every defined as an option - not the
    person name or locale data.

  ### Notes

  The formats may be the same for different lengths
  depending on the formality, usage, and cultural conventions
  for the locale.

  For example, medium and short may be the same for a
  particular context.

  ### Returns

  * `{:ok, formatted_name_as_iodata}` or

  * `{:error, reason}`.

  ### Examples

      iex> {:ok, jose} = Cldr.PersonName.new(title: "Mr.", given_name: "José", surname: "Valim", credentials: "Ph.D.", locale: "pt")
      iex> Cldr.PersonName.to_iodata(jose)
      {:ok, ["José"]}
      iex> Cldr.PersonName.to_iodata(jose, format: :long)
      {:ok, ["José"]}
      iex> Cldr.PersonName.to_iodata(jose, format: :long, formality: :formal)
      {:ok, ["Mr.", " ", "Valim"]}
      iex> Cldr.PersonName.to_iodata(jose, format: :long, formality: :formal, usage: :referring)
      {:ok, ["Mr.", " ", "José", " ", "Valim", ", ", "Ph.D."]}

  """

  @spec to_iodata(person_name :: struct(), options :: Formatter.format_options()) ::
    {:ok, :erlang.iodata()} | {:error, error_message()}

  def to_iodata(person_name, options \\ []) when is_struct(person_name) do
    {locale, backend} = Cldr.locale_and_backend_from(options)

    with {:ok, person_name} <- maybe_cast_name(person_name),
         {:ok, formatting_locale} <- Cldr.validate_locale(locale, backend) do
      Formatter.to_iodata(person_name, formatting_locale, backend, options)
    end
  end

  @spec to_iodata!(person_name :: struct(), options :: Formatter.format_options()) ::
    :erlang.iodata() | no_return()

  def to_iodata!(person_name, options \\ []) when is_struct(person_name) do
    case to_iodata(person_name, options) do
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

  ### Arguments

  * `struct` is any struct that implements the
    `#{inspect __MODULE__}` behaviour.

  ### Returns

  * A `t:Cldr.PersonName.t/0` struct.

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
  @doc false
  def title(%__MODULE__{title: title}),
    do: title

  @impl Cldr.PersonName
  @doc false
  def given_name(%__MODULE__{given_name: given_name}),
    do: given_name

  @impl Cldr.PersonName
  @doc false
  def other_given_names(%__MODULE__{other_given_names: other_given_names}),
    do: other_given_names

  @impl Cldr.PersonName
  @doc false
  def informal_given_name(%__MODULE__{informal_given_name: informal_given_name}),
    do: informal_given_name

  @impl Cldr.PersonName
  @doc false
  def surname_prefix(%__MODULE__{surname_prefix: surname_prefix}),
    do: surname_prefix

  @impl Cldr.PersonName
  @doc false
  def surname(%__MODULE__{surname: surname}),
    do: surname

  @impl Cldr.PersonName
  @doc false
  def other_surnames(%__MODULE__{other_surnames: other_surnames}),
    do: other_surnames

  @impl Cldr.PersonName
  @doc false
  def generation(%__MODULE__{generation: generation}),
    do: generation

  @impl Cldr.PersonName
  @doc false
  def credentials(%__MODULE__{credentials: credentials}),
    do: credentials

  @impl Cldr.PersonName
  @doc false
  def locale(%__MODULE__{locale: locale}),
    do: locale

  @impl Cldr.PersonName
  @doc false
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
  @non_string_attributes [:locale, :backend, :preferred_order]
  @string_attributes Keyword.keys(@person_name) -- @non_string_attributes
  @all_attributes @string_attributes ++ @non_string_attributes
  @valid_name_order Formatter.valid_name_order()

  defp validate_name(attributes) when is_list(attributes) do
    validated =
      Enum.reduce_while attributes, %__MODULE__{}, fn
        {attribute, value}, acc when attribute in @string_attributes and is_binary(value) ->
          {:cont, Map.put(acc, attribute, value)}

        {attribute, nil}, acc when attribute in @all_attributes  ->
          {:cont, Map.put(acc, attribute, nil)}

        {:locale, %Cldr.LanguageTag{} = locale}, acc ->
           {:cont, Map.put(acc, :locale, locale)}

        {:locale, _locale_reference}, acc ->
          case validate_locale(attributes) do
            {:ok, locale} -> {:cont, Map.put(acc, :locale, locale)}
            other -> {:halt, other}
          end

        {:preferred_order, preferred_order}, acc when preferred_order in @valid_name_order ->
          {:cont, Map.put(acc, :preferred_order, preferred_order)}

        {:backend, _backend}, acc ->
          {:cont, acc}

        {attribute, _value}, _acc when attribute not in @all_attributes ->
          {:halt, {:error, "Invalid attribute found: #{inspect attribute}. Valid attributes are #{inspect @all_attributes}"}}

        {attribute, value}, _acc ->
          {:halt, {:error, "Invalid attribute value found for #{inspect attribute}. Found #{inspect value}"}}
      end

    case validated do
      {:error, reason} ->
        {:error, reason}

      %__MODULE__{} = person_name ->
        validate_given_name_presence(person_name)
    end
  end

  # The contract is that the %__MODULE__{} struct is structurally
  # sound so we just check there is a `:given_name`.
  defp validate_name(%{} = person_name) do
    validate_given_name_presence(person_name)
  end

  defp validate_locale(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    Cldr.validate_locale(locale, backend)
  end

  defp validate_given_name_presence(%{} = person_name) do
    if person_name.given_name do
      {:ok, person_name}
    else
      {:error, "Person Name requires at least a :given_name"}
    end
  end

  defp raise_error(reason) when is_binary(reason) do
    raise Cldr.PersonNameError, reason
  end

  defp raise_error({exception, message}) do
    raise exception, message
  end
end
