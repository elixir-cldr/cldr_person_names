defmodule Cldr.PersonName do
  @moduledoc """
  Cldr module to formats person names.

  """

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

  @default_order :given_first
  @default_format :medium
  @default_usage :addressing
  @default_formality :formal

  import Kernel, except: [to_string: 1]

  defdelegate cldr_backend_provider(config),
    to: Cldr.PersonName.Backend,
    as: :define_backend_module

  defguardp is_initial(term) when is_list(term)

  def new(options \\ []) do
    with {:ok, validated} <- validate_name(options) do
      {:ok, struct(__MODULE__, validated)}
    end
  end

  def to_string(%__MODULE__{} = name, options \\ []) do
    with {:ok, iodata} <- to_iodata(name, options) do
      {:ok, :erlang.iolist_to_binary(iodata)}
    end
  end

  def to_string!(%__MODULE__{} = name, options \\ []) do
    case to_string(name, options) do
      {:ok, formatted_name} -> formatted_name
      {:error, reason} -> raise Cldr.PersonNameError, reason
    end
  end

  def to_iodata(%__MODULE__{} = name, options \\ []) do
    {locale, backend} = Cldr.locale_and_backend_from(options)

    with {:ok, formatting_locale} <- Cldr.validate_locale(locale, backend),
         {:ok, options} <- validate_options(options),
         {:ok, name} <- validate_name(name),
         {:ok, name_locale} <- derive_name_locale(name, formatting_locale) |> IO.inspect(label: "Name locale"),
         {:ok, formats, templates} <- get_formats(name_locale, backend) |> IO.inspect(label: "Formats"),
         {:ok, options} <- determine_name_order(name, name_locale, backend, options),
         {:ok, format} <- select_format(formats, options) do
      name
      |> interpolate_format(format, templates)
      |> join_initials(templates)
      |> wrap(:ok)
    end
  end

  def to_iodata!(%__MODULE__{} = name, options \\ []) do
    case to_iodata(name, options) do
      {:ok, iodata} -> iodata
      {:error, reason} -> raise Cldr.PersonNameError, reason
    end
  end

  #
  # Interpolate the format
  #

  defp interpolate_format(name, [first], templates) do
    if formatted_first = interpolate_element(name, first, templates) do
      [formatted_first]
    else
      []
    end
  end

  # Omit any leading whitespace if the last field isn't
  # available
  defp interpolate_format(name, [literal, last], templates) when is_binary(literal) do
    formatted_last = interpolate_element(name, last, templates)

    if length(formatted_last) > 0 do
      [literal | formatted_last]
    else
      []
    end
  end

  # Two elements separated by a string (typically whitespace). Only include the string
  # if both elements return a format.
  defp interpolate_format(name, [first, literal | rest], templates) when is_binary(literal) do
    formatted_rest = interpolate_format(name, rest, templates)
    formatted_first = interpolate_element(name, first, templates)

    cond do
      formatted_first && length(formatted_rest) > 0 ->
        [formatted_first, literal | formatted_rest]

      formatted_first ->
        [formatted_first]

      length(formatted_rest) > 0 ->
        formatted_rest

      true ->
        []
    end
  end

  # Two elements not separated by whitespace (like monograms)
  defp interpolate_format(name, [first | rest], templates) do
    formatted_rest = interpolate_format(name, rest, templates)
    formatted_first = interpolate_element(name, first, templates)

    cond do
      formatted_first && length(formatted_rest) > 0 ->
        [formatted_first | formatted_rest]

      formatted_first ->
        [formatted_first]

      length(formatted_rest) > 0 ->
        formatted_rest

      true ->
        []
    end
  end

  #
  # Format each element
  #

  defp interpolate_element(%{prefix: prefix}, [:prefix | transforms], templates)
       when is_binary(prefix) do
    format_element(prefix, transforms, templates)
  end

  defp interpolate_element(%{title: title}, [:title | transforms], templates)
       when is_binary(title) do
    format_element(title, transforms, templates)
  end

  defp interpolate_element(name, [:given, :informal | transforms], templates) do
    cond do
      name.informal_given_name ->
        format_element(name.informal_given_name, transforms, templates)

      name.given_name ->
        format_element(name.given_name, transforms, templates)

      true ->
        nil
    end
  end

  defp interpolate_element(%{given_name: given_name}, [:given | transforms], templates)
       when is_binary(given_name) do
    format_element(given_name, transforms, templates)
  end

  defp interpolate_element(
         %{other_given_names: other_given_names},
         [:given2 | transforms],
         templates
       )
       when is_binary(other_given_names) do
    format_element(other_given_names, transforms, templates)
  end

  defp interpolate_element(%{surname: surname}, [:surname | transforms], templates)
       when is_binary(surname) do
    format_element(surname, transforms, templates)
  end

  defp interpolate_element(%{other_surnames: other_surnames}, [:surname2 | transforms], templates)
       when is_binary(other_surnames) do
    format_element(other_surnames, transforms, templates)
  end

  defp interpolate_element(%{generation: generation}, [:generation | transforms], templates)
       when is_binary(generation) do
    format_element(generation, transforms, templates)
  end

  defp interpolate_element(%{credentials: credentials}, [:credentials | transforms], templates)
       when is_binary(credentials) do
    format_element(credentials, transforms, templates)
  end

  defp interpolate_element(_name, _element, _templates) do
    nil
  end

  #
  # Formmatting transforms
  #

  defp format_element(value, transforms, {initial_template, _initial_sequence} = templates) do
    Enum.reduce(transforms, value, fn
      :all_caps, value ->
        String.upcase(value)

      :monogram, value ->
        String.first(value)

      :prefix, _value ->
        nil

      :core, value ->
        value

      :initial_cap, value ->
        String.capitalize(value)

      :initial, value ->
        value
        |> Unicode.String.split(break: :word, trim: true)
        |> Enum.map(fn word ->
          word
          |> String.first()
          |> Cldr.Substitution.substitute(initial_template)
          |> join_initials(templates)
        end)
    end)
  end

  defp join_initials([first], _templates) do
    [first]
  end

  defp join_initials([first, second | rest], {_initial, sequence} = templates)
       when is_initial(first) and is_initial(second) do
    join_initials([Cldr.Substitution.substitute([first, second], sequence) | rest], templates)
  end

  defp join_initials([first | rest], templates) do
    [first | join_initials(rest, templates)]
  end

  #
  # Helpers
  #

  defp validate_name(%{surname: surname, given_name: given_name} = name)
       when is_binary(surname) or is_binary(given_name) do
    {:ok,  name}
  end

  defp validate_name(name) do
    {:error,
     "Name requires at least one of the fields :surname and :given_name. Found #{inspect(name)}"}
  end

  # Construct the **name script** in the following way:
  #
  # 1. Iterate through the characters of the surname, then through the given name.
  #     1. Find the script of that character using the Script property.
  #     2. If the script is not Common, Inherited, nor Unknown, return that script as the
  #     **name script**
  #
  # 2. If nothing is found during the iteration, return Zzzz (Unknown Script)
  #
  # Construct the **name base language** in the following way:
  #
  # 1. If the PersonName object can provide a name locale, return its language.
  #
  # 2. Otherwise, find the maximal likely locale for the name script, using Likely Subtags,
  #    and return its base language (first subtag).
  #
  # Construct the **name locale** in the following way:
  #
  # 1. If the PersonName object can provide a name locale, return a locale formed from it
  #    by replacing its script by the name script.
  #
  # 2. Otherwise, return the locale formed from the name base language plus name script.

  defp derive_name_locale(%{locale: %Cldr.LanguageTag{} = name_locale} = name, _formatting_locale) do
    name_script = dominant_script(name)

    if name_locale.script == name_script do
      {:ok, name_locale} |> IO.inspect(label: "Using name locale with script #{inspect name_script}}")
    else
      locale_name = Cldr.Locale.locale_name_from(name_locale.language, name_script, name_locale.territory, [])
      {:ok, formatting_locale} = Cldr.validate_locale(locale_name, name_locale.backend)
    end
  end

  defp derive_name_locale(%{locale: nil} = name, formatting_locale) do
    name_script = dominant_script(name)
    name_locale = find_likely_locale_for_script(name_script, formatting_locale.backend)

    if name_locale do
      {:ok, name_locale}
    else
      {:error, "No locale resolved for script #{inspect name_script}"}
    end
  end

  defp dominant_script(name) do
    name
    |> Map.take([:surname, :given_name])
    |> Map.values()
    |> Enum.filter(&is_binary/1)
    |> Enum.join()
    |> Unicode.script()
    |> Enum.reject(&(&1 in [:common, :inherited, :unknown]))
    |> resolve_cldr_script_name()
  end

  # No script found, return :unknown script
  defp resolve_cldr_script_name([]) do
    Cldr.Validity.Script.unicode_to_subtag!(:unknown)
  end

  # Need to map for Unicodes name for a script (like `:latin`)
  # to CLDRs encoding which is `:Latn`
  defp resolve_cldr_script_name([name]) do
    Cldr.Validity.Script.unicode_to_subtag!(name)
  end

  defp find_likely_locale_for_script(script, backend) do
    root_language = Cldr.Locale.root_language()
    likely_locale = Cldr.Locale.likely_subtags(root_language, script, nil, [])
    likely_locale && Cldr.Locale.canonical_language_tag(likely_locale, backend)
  end

  defp validate_options(options) do
    options =
      default_options()
      |> Keyword.merge(options)
      |> Keyword.take([:order, :format, :usage, :formality])

    Enum.reduce_while(options, {:ok, options}, fn
      {:format, value}, acc when value in [:short, :medium, :long] ->
        {:cont, acc}

      {:usage, value}, acc when value in [:addressing, :referring, :monogram] ->
        {:cont, acc}

      {:order, value}, acc when value in [:given_first, :surname_first, :sorting] ->
        {:cont, acc}

      {:formality, value}, acc when value in [:formal, :informal] ->
        {:cont, acc}

      {option, value}, _acc ->
        {:halt, {:error, "Invalid value #{inspect(value)} for option #{inspect(option)}"}}
    end)
  end

  defp get_formats(locale, backend) do
    backend = Module.concat(backend, PersonName)
    formats = backend.formats_for(locale) || backend.formats_for(:und)
    initial = Map.fetch!(formats, :initial)
    initial_sequence = Map.fetch!(formats, :initial_sequence)
    {:ok, formats, {initial, initial_sequence}}
  end

  defp determine_name_order(name, name_locale, backend, options) do
    language = name_locale.language
    backend = Module.concat(backend, PersonName)
    locale_order = backend.locale_order(name_locale) || backend.locale_order(:und)

    IO.inspect options[:order], label: "Options order"
    IO.inspect name.preferred_order, label: "Name preferred order"
    IO.inspect locale_order[language], label: "Language order"
    IO.inspect locale_order[language], label: "Und order"

    order =
      options[:order] || name.preferred_order || locale_order[language] || locale_order["und"] || @default_order
      |> IO.inspect(label: "Name order")

    {:ok, Keyword.put(options, :order, order)}
  end

  defp select_format(formats, options) do
    keys = [:person_name, options[:order], options[:format], options[:usage], options[:formality]]

    case get_in(formats, keys) do
      nil ->
        {:error, "No format found for options #{inspect(options)}"}

      format ->
        {:ok, format}
    end
  end

  defp wrap(term, atom) do
    {atom, term}
  end

  defp default_options do
    [
      format: @default_format,
      usage: @default_usage,
      formality: @default_formality
    ]
  end
end
