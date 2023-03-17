defmodule Cldr.PersonName do
  @moduledoc """
  Cldr module to formats person names.

  """

  @person_name [
    locale: nil,
    prefix: nil,
    title: nil,
    given_name: nil,
    other_given_names: nil,
    informal_given_name: nil,
    surname: nil,
    other_surnames: nil,
    generation: nil,
    credentials: nil,
    preferred_order: :given_first
  ]

  defstruct @person_name

  @default_order :given_first
  @default_format :medium
  @default_usage :addressing
  @default_formality :informal

  defdelegate cldr_backend_provider(config), to: Cldr.PersonName.Backend, as: :define_backend_module

  def new(options \\ []) do
    with {:ok, validated} <- validate_name(options) do
      {:ok, struct(__MODULE__, validated)}
    end
  end

  def to_iodata(%__MODULE__{} = name, options \\ []) do
    {locale, backend} = Cldr.locale_and_backend_from(options)

    with {:ok, name} <- validate_name(name),
         {:ok, options} <- validate_options(options),
         {:ok, formats, templates} <- get_formats(locale, backend),
         {:ok, options} <- determine_name_order(name, locale, backend, options),
         {:ok, format} <- resolve_format(formats, options) do
      name
      |> interpolate_format(format, templates)
      |> join_initials(templates)
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
    if formatted_last = interpolate_element(name, last, templates) do
      [literal, formatted_last]
    else
      []
    end
  end

  # Omit trailing whitespace if a field isn't available.
  defp interpolate_format(name, [first | rest], templates) do
    formatted_rest = interpolate_format(name, rest, templates)
    formatted_first = interpolate_element(name, first, templates)

    if formatted_first do
      [formatted_first | formatted_rest]
    else
      formatted_rest
    end
  end

  #
  # Format each element
  #

  defp interpolate_element(%{prefix: prefix}, [:given_name2 | transforms], templates)
      when is_binary(prefix) do
    format_element(prefix, transforms, templates)
  end

  defp interpolate_element(%{title: title}, [:title | transforms], templates)
      when is_binary(title) do
    format_element(title, transforms, templates)
  end

  defp interpolate_element(%{informal_given_name: informal_given_name}, [:given, :informal | transforms], templates)
      when is_binary(informal_given_name) do
    format_element(informal_given_name, transforms, templates)
  end

  defp interpolate_element(%{given_name: given_name}, [:given | transforms], templates)
      when is_binary(given_name) do
    format_element(given_name, transforms, templates)
  end

  defp interpolate_element(%{other_given_names: other_given_names}, [:given2 | transforms], templates)
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
  # Formmatters
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
      when is_list(first) and is_list(second) do
    join_initials([Cldr.Substitution.substitute([first, second], sequence) | rest], templates)
  end

  defp join_initials([first | rest], templates) do
    [first | join_initials(rest, templates)]
  end

  #
  # Helpers
  #

  defp validate_name(%{surname: surname, given_name: given_name} = name)
      when is_binary(surname) and is_binary(given_name) do
    {:ok, name}
  end

  defp validate_name(name) do
    {:error, "Name requires at least the fields :surname and :given_name. Found #{inspect name}"}
  end

  defp validate_options(options) do
    options =
      default_options()
      |> Keyword.merge(options)
      |> Keyword.take([:order, :format, :usage, :formality])

    Enum.reduce_while(options, {:ok, options}, fn
      {:format, value}, acc when value in [:short,:medium, :long] ->
        {:cont, acc}

      {:usage, value}, acc when value in [:addressing, :referring, :monogram] ->
        {:cont, acc}

      {:order, value}, acc when value in [:given_first, :surname_first, :sorting] ->
        {:cont, acc}

      {:formality, value}, acc when value in [:formal, :informal] ->
        {:cont, acc}

      {option, value}, _acc ->
        {:halt, {:errpr, "Invalid value #{inspect value} for option #{inspect option}"}}
    end)
  end

  defp get_formats(locale, backend) do
    backend = Module.concat(backend, PersonName)
    formats = backend.formats_for(locale) || backend.formats_for(:und)
    initial = Map.fetch!(formats, :initial)
    initial_sequence = Map.fetch!(formats, :initial_sequence)
    {:ok, formats, {initial, initial_sequence}}
  end

  defp determine_name_order(name, %Cldr.LanguageTag{language: language} = locale, backend, options) do
    backend = Module.concat(backend, PersonName)
    locale_order = backend.locale_order(locale) || backend.locale_order(:und)
    order = options[:order] || name.preferred_order || locale_order[language] || locale_order["und"]
    {:ok, Keyword.put(options, :order, order)}
  end

  defp resolve_format(formats, options) do
    keys = [:person_name, options[:order], options[:format], options[:usage], options[:formality]]

    case get_in(formats, keys) do
      nil ->
        {:error, "No format found for options #{inspect options}"}

      format ->
        {:ok, format}
    end
  end

  defp default_options do
    [
      format: @default_format,
      usage: @default_usage,
      formality: @default_formality,
      order: @default_order
    ]
  end
end
