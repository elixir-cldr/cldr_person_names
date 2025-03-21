defmodule Cldr.PersonName.Formatter do
  @moduledoc """
  Implements the person name formatting specification.

  """

  type_from_list = &Enum.reduce(&1, fn x, acc -> {:|, [], [x, acc]} end)

  @format [:short, :medium, :long]
  @usage [:addressing, :referring, :monogram]
  @formality [:formal, :informal]
  @default_usage :addressing
  @preferred_order [:given_first, :surname_first, :sorting]

  @format_options [:format, :usage, :order, :formality, :locale]

  @typedoc "Valid :format option"
  @type format :: unquote(type_from_list.(@format))

  @typedoc "Valid :name_order option"
  @type name_order :: unquote(type_from_list.(@preferred_order))

  @typedoc "Valid :usage option"
  @type usage  :: unquote(type_from_list.(@usage))

  @typedoc "Valid :formality option"
  @type formality :: unquote(type_from_list.(@formality))

  @typedoc "Valid options for Cldr.PersonName.to_string/2"
  @type format_option ::
    {:format, format()}
    | {:backend, module()}
    | {:name_order, name_order()}
    | {:usage, usage()}
    | {:formality, formality()}
    | {:locale, Cldr.Locale.locale_reference()}

  @typedoc "Cldr.PersonName.to_string/2 options list"
  @type format_options :: list(format_option())

  # These languages will have a different String.upcase/1 treatment than the default.
  # Taken from https://www.medicaldirector.com/help/topics-clinical/Language_Codes.htm
  # Turkish, Azeri, Tatar, Turkmen, Uygur, Uzbek
  @turkic_languages [:tr, :az, :tt, :tk, :ug, :uz]

  # Preference is given to the name's preferred order, then the locales preferred
  # order, then this default order.
  @default_order :given_first

  # ASCII space used in the templates
  @format_space " "

  defguardp is_initial(term) when is_list(term)

  @doc false
  def valid_name_order do
    [:given_first, :surname_first, :sorting]
  end

  @doc false
  def to_iodata(name, formatting_locale, backend, options) do
    with {:ok, name_locale} <- derive_name_locale(name, formatting_locale),
         # {:ok, formatting_locale} <- derive_formatting_locale(name, formatting_locale, name_locale),
         {:ok, formats} <-formats(formatting_locale, backend),
         {:ok, options} <- validate_options(formats, options),
         {:ok, options} <- determine_name_order(name, name_locale, backend, options),
         {:ok, format} <- select_format(name, formats, options),
         {:ok, name, format} <- adjust_for_mononym(name, format) do
      name
      |> interpolate_format(formatting_locale, format, formats)
      |> foreign_or_native_space_replacement(name_locale, formatting_locale, formats)
      |> wrap(:ok)
    end
  end

  defp validate_options(formats, options) do
    options =
      default_options(formats)
      |> Keyword.merge(options)
      |> Keyword.delete(:locale)
      |> Keyword.take(@format_options)

    Enum.reduce_while(options, {:ok, options}, fn
      {:format, value}, acc when value in @format ->
        {:cont, acc}

      {:usage, value}, acc when value in @usage ->
        {:cont, acc}

      {:order, value}, acc when value in @preferred_order ->
        {:cont, acc}

      {:formality, value}, acc when value in @formality ->
        {:cont, acc}

      {option, value}, _acc when option in @format_options ->
        {:halt, {:error, "Invalid value #{inspect value} for option #{inspect option}"}}

      {option, _value}, _acc ->
        {:halt, {:error, "Invalid option #{inspect(option)}"}}
    end)
  end

  defp default_options(formats) do
    [
      format: formats.length,
      formality: formats.formality,
      usage: @default_usage,
    ]
  end

  # Interpolate the format
  # https://www.unicode.org/reports/tr35/tr35-personNames.html#process-a-namepattern
  #
  # If one or more fields at the start of the pattern are empty, all fields and literal text before
  # the first populated field are omitted.
  #
  # If one or more fields at the end of the pattern are empty, all fields and literal text after
  # the last populated field are omitted.
  #
  # Processing from the start of the remaining pattern:
  #   If there are two or more empty fields separated only by literals, the fields and the literals
  #   between them are removed.
  #
  #   If there is a single empty field, it is removed.
  #
  #   If the processing from step 3 results in two adjacent literals (call them A and B), they are
  #   coalesced into one literal as follows:
  #
  #     If either is empty the result is the other one.
  #     If B matches the end of A, then the result is A. So xyz + yz ⇒ xyz, and xyz + xyz ⇒ xyz.
  #     Otherwise the result is A + B, further modified by replacing any sequence of two or more
  #     white space characters by the first whitespace character.

  @doc false
  def interpolate_format(name, locale, elements, formats) do
    elements
    |> Enum.map(&interpolate_element(name, &1, locale, formats))
    |> remove_leading_emptiness()
    |> remove_trailing_emptiness()
    |> remove_empty_fields()
    |> extract_values()
  end

  # If one or more fields at the start of the pattern are empty, all fields and literal text before
  # the first populated field are omitted. In this implementation, just remove the start of the
  # list until we get to a value. Unlike the standard text (but consistent with ICU) a binary
  # before the first populated field is ok.

  @doc false
  def remove_leading_emptiness([{:field, value} | rest]), do: [{:field, value} | rest]
  def remove_leading_emptiness([_first | rest]), do: remove_leading_emptiness(rest)
  def remove_leading_emptiness([]), do: []

  # If one or more fields at the end of the pattern are empty, all fields and literal text after
  # the last populated field are omitted.

  @doc false
  def remove_trailing_emptiness(elements) do
    elements
    |> Enum.reverse()
    |> maybe_remove_leading_emptiness()
    |> Enum.reverse()
  end

  @doc false
  def maybe_remove_leading_emptiness(elements) do
    Enum.reduce_while(elements, nil, fn
      # We found an empty element before any populated elements
      # So remove the leading emptiness
      nil, _acc ->
        {:halt, remove_leading_emptiness(elements)}

      # We found a populated element first
      # So we don't remove emptiness
      {:field, _value}, _acc ->
        {:halt, elements}

      # Keep looking for a populated or unpopulated
      # field
      _other, acc ->
        {:cont, acc}
    end)
  end

  # Processing from the start of the remaining pattern:
  # https://www.unicode.org/reports/tr35/tr35-personNames.html#process-a-namepattern
  #
  #   If there are two or more empty fields separated only by literals, the fields and the literals
  #   between them are removed.
  #
  #   If there is a single empty field, it is removed.
  #
  #   If the processing from step 3 results in two adjacent literals (call them A and B), they are
  #   coalesced into one literal as follows:
  #
  #     If either is empty the result is the other one.
  #     If B matches the end of A, then the result is A. So xyz + yz ⇒ xyz, and xyz + xyz ⇒ xyz.
  #     Otherwise the result is A + B, further modified by replacing any sequence of two or more
  #     white space characters by the first whitespace character.

  #  The spec doens't say what to do with a sequence of binaries intersperesed
  #  with unpopulated fields (nil).  Based upon the test cases this implementation:
  #
  #    1. Deletes an unpopulated field immediately after a populated field
  #    2. Deletes an unpopulated field (nil) *and* a binary is the binary directly follows
  #       the unpopulated field and the binary is whitespace.

  @doc false
  def remove_empty_fields([nil | rest]) do
    case remove_up_to_nil(rest) do
      [] -> remove_empty_fields(rest)
      rest -> remove_empty_fields(rest)
    end
  end

  def remove_empty_fields([first | rest]) when is_binary(first) do
    case remove_empty_fields(rest) do
      [binary | rest] when is_binary(binary) ->
        [combine_binary(first, binary) | rest]

      other ->
        [first | other]
    end
  end

  def remove_empty_fields([first | rest]) do
    [first | remove_empty_fields(rest)]
  end

  def remove_empty_fields([]) do
    []
  end

  # We found a populated value before another unpopulated one
  # so that rule doesn't apply
  defp remove_up_to_nil([{:field, _value} | _rest]),
    do: []

  # We found another unpopulated value to we are done
  defp remove_up_to_nil([nil | rest]),
    do: rest

  # We found a binary so consume it
  defp remove_up_to_nil([binary | rest]) when is_binary(binary),
    do: remove_up_to_nil(rest)

  #   If the processing from step 3 results in two adjacent literals (call them A and B), they are
  #   coalesced into one literal as follows:
  #
  #     If either is empty the result is the other one.
  #     If B matches the end of A, then the result is A. So xyz + yz ⇒ xyz, and xyz + xyz ⇒ xyz.
  #     Otherwise the result is A + B, further modified by replacing any sequence of two or more
  #     white space characters by the first whitespace character.

  @doc false
  def combine_binary(first, ""), do: first
  def combine_binary("", second), do: second
  def combine_binary(first, first), do: first

  @doc false
  def combine_binary(first, second) do
    if String.ends_with?(first, second) do
      first
    else
      remove_duplicate_whitespace(first <> second)
    end
    |> bodgy_fix_literal()
  end

  # FIXME This is here to make some test cases pass until
  # either the data bug (id, es) is fixed or the spec is updated
  # or I find more evidence of my idiocy.
  # See https://unicode-org.atlassian.net/jira/software/c/projects/CLDR/issues/CLDR-17443

  defp bodgy_fix_literal(string) do
    if Regex.match?(~r/^\s+/u, string) && Regex.match?(~r/\s+$/u, string) do
      # String.trim_leading(string)
      @format_space
    else
      string
    end
  end

  # Replace multiple whitespace with the first
  # whitespace grapheme.
  @doc false
  def remove_duplicate_whitespace(string) do
    case Regex.named_captures(~r/(?<whitespace>\s+)/u, string) do
      %{"whitespace" => whitespace} ->
        replacement = String.first(whitespace)
        String.replace(string, ~r/\s+/u, replacement)
      nil ->
        string
    end
  end

  defp extract_values(elements) do
    Enum.map(elements, fn
      {:field, value} -> value
      other -> other
    end)
  end

  # Setting the space replacement
  #
  # The foreignSpaceReplacement is provided by the value for the foreignSpaceReplacement element;
  # the default value is a SPACE (" ").
  #
  # The nativeSpaceReplacement is provided by the value for the nativeSpaceReplacement element; the
  # default value is SPACE (" ").
  #
  # If the formatter base language matches the name base language, then let spaceReplacement =
  # nativeSpaceReplacement, otherwise let spaceReplacement = foreignSpaceReplacement.
  #
  # Replace all sequences of space in the formatted value string by the spaceReplacement.
  #
  # For the purposes of this algorithm, two base languages are said to match when they are
  # identical, or if both are in {ja, zh, yue}.

  @doc false
  def foreign_or_native_space_replacement(list, name_locale, formatting_locale, formats) do
    replacement = foreign_or_native(name_locale.language, formatting_locale.language, formats)

    Enum.map(list, fn
      @format_space -> replacement
      other -> String.replace(other, @format_space, replacement)
    end)
  end

  @doc false
  def foreign_or_native(name_language, formatting_language, formats) do
    if considered_the_same_language?(name_language, formatting_language) do
      formats.native_space_replacement
    else
      formats.foreign_space_replacement
    end
  end

  defp considered_the_same_language?(language, language) do
    true
  end

  defp considered_the_same_language?(name_language, formatting_language) do
    name_language in [:ja, :zh, :yue] && formatting_language in [:ja, :zh, :yue]
  end

  @considered_the_same [:Jpan, :Hani, :Kana, :Hira]
  defp considered_the_same_script?(name_script, name_script) do
    true
  end

  defp considered_the_same_script?(name_script, formatting_script) do
    name_script in @considered_the_same and formatting_script in @considered_the_same
  end

  @doc false
  def wrap(term, atom) do
    {atom, term}
  end

  #
  # Format each element
  #

  # Handle missing surname
  #
  # All PersonName objects will have a given name (for mononyms the given name is used). However,
  # there may not be a surname. In that case, the following process is followed so that formatted
  # patterns produce reasonable results.
  #
  # If there is no surname from a PersonName P1 and the pattern either doesn't include the given
  # name or only shows an initial for the given name, then:
  #   Construct and use a derived PersonName P2, whereby P2 behaves exactly as P1 except that:
  #   Any request for a surname field (with any modifiers) returns P1's given name (with the same
  #.  modifiers)
  #   Any request for a given name field (with any modifiers) returns "" (empty string)

  @doc false
  def adjust_for_mononym(%{surname: surname} = name, format) when is_binary(surname) do
    {:ok, name, format}
  end

  def adjust_for_mononym(name, format) do
    if format_has_full_given_name?(format) do
      {:ok, name, format}
    else
      name = move_given_to_surname(name)
      format = force_given_name_to_binary(format)
      {:ok, name, format}
    end
  end

  defp format_has_full_given_name?(format) do
    Enum.any?(format, &(is_list(&1) && hd(&1) == :given && :initial not in &1))
  end

  defp move_given_to_surname(name) do
    name
    |> Map.put(:surname, name.given_name)
    |> Map.put(:given_name, nil)
  end

  defp force_given_name_to_binary(format) do
    Enum.map(format, fn
      [:given_name | _rest] -> ""
      other -> other
    end)
  end

  defp interpolate_element(%{title: title}, [:title | transforms], locale, formats) do
    format_element(title, locale, transforms, formats)
  end

  defp interpolate_element(name, [:given, :informal | transforms], locale, formats) do
    format_element(name.informal_given_name || name.given_name, locale, transforms, formats)
  end

  defp interpolate_element(%{given_name: given_name}, [:given | transforms], locale, formats) do
    format_element(given_name, locale, transforms, formats)
  end

  defp interpolate_element(
         %{other_given_names: other_given_names},
         [:given2 | transforms],
         locale,
         formats
       )
       when is_binary(other_given_names) do
    format_element(other_given_names, locale, transforms, formats)
  end

  defp interpolate_element(
         %{surname_prefix: surname_prefix},
         [:surname, :prefix | transforms],
         locale,
         formats
       ) do
    format_element(surname_prefix, locale, transforms, formats)
  end

  defp interpolate_element(%{surname: surname}, [:surname, :core | transforms], locale, formats) do
    format_element(surname, locale, transforms, formats)
  end

  defp interpolate_element(name, [:surname, :monogram | transforms], locale, formats) do
    complete_surname = format_surname(name, locale, transforms, formats)

    if Enum.empty?(complete_surname) do
      nil
    else
      complete_surname
      |> :erlang.iolist_to_binary()
      |> monogram(locale)
      |> wrap(:field)
    end
  end

  defp interpolate_element(name, [:surname | transforms], locale, formats) do
    complete_surname =
      name
      |> format_surname(locale, transforms, formats)
      |> Enum.intersperse(@format_space)

    if Enum.empty?(complete_surname) do
      nil
    else
      complete_surname
      |> :erlang.iolist_to_binary()
      |> wrap(:field)
    end
  end

  defp interpolate_element(
         %{other_surnames: other_surnames},
         [:surname2 | transforms],
         locale,
         formats
       )
       when is_binary(other_surnames) do
    format_element(other_surnames, locale, transforms, formats)
  end

  defp interpolate_element(%{generation: generation}, [:generation | transforms], locale, formats)
       when is_binary(generation) do
    format_element(generation, locale, transforms, formats)
  end

  defp interpolate_element(
         %{credentials: credentials},
         [:credentials | transforms],
         locale,
         formats
       )
       when is_binary(credentials) do
    format_element(credentials, locale, transforms, formats)
  end

  defp interpolate_element(_name, element, _locale, _formats) when is_binary(element) do
    element
  end

  defp interpolate_element(_name, _element, _locale, _formats) do
    nil
  end

  #
  # Formmatting transforms
  #

  defp format_element(nil, _locale, _transforms, _formats) do
    nil
  end

  defp format_element(value, locale, transforms, formats) do
    Enum.reduce(transforms, value, fn
      :all_caps, value ->
        language_mode = mode_from_locale(locale)
        String.upcase(value, language_mode)

      :monogram, value ->
        monogram(value, locale)

      :initial_cap, value ->
        language_mode = mode_from_locale(locale)
        String.capitalize(value, language_mode)

      :initial, value ->
        initialize_value(value, locale, transforms, formats)

      _other, value ->
        value
    end)
    |> wrap(:field)
  end

  defp format_surname(name, locale, [:initial | transforms], formats) do
    surname_prefix = format_element(name.surname_prefix, locale, [:initial | transforms], formats)
    surname = format_element(name.surname, locale, [:initial | transforms], formats)

    [surname_prefix, surname]
    |> extract_values()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&[&1])
    |> join_initials(formats)
  end

  defp format_surname(name, locale, transforms, formats) do
    surname_prefix = format_element(name.surname_prefix, locale, transforms, formats)
    surname = format_element(name.surname, locale, transforms, formats)

    [surname_prefix, surname]
    |> extract_values()
    |> Enum.reject(&is_nil/1)
  end

  defp initialize_value(value, locale, transforms, formats) do
    retain_punctuation? =
      Enum.any?(transforms, &(&1 == :retain))

    value
    |> Unicode.String.split(break: :word, trim: true, locale: locale)
    |> Enum.reduce([], &initialize_word(&1, locale, formats.initial, &2, retain_punctuation?))
    |> Enum.reverse()
    |> join_initials(formats)
    |> :erlang.iolist_to_binary()
  end

  # Starts with a letter, then letter or punctuation or a extended character
  @word_or_punctuation Unicode.Regex.compile!("^\\p{L}[\\p{L}\\p{P}\\p{word_break=extend}]*$")

  # If we aren't retaining punctuation, then we discard
  # any punctuation.

  defp initialize_word(word, locale, initial_template, acc, false = _retain_punctuation?) do
    if Unicode.Regex.match?(@word_or_punctuation, word) do
      add_initial(word, locale, initial_template, acc)
    else
      acc
    end
  end

  # If we are keeping punctuation then its added, but in a way
  # that we know its a literal, not an initial. Thats important
  # later on when we join things up.

  defp initialize_word(word, locale, initial_template, acc, true = _retain_punctuation?) do
    if Unicode.Regex.match?(@word_or_punctuation, word) do
      add_initial(word, locale, initial_template, acc)
    else
      add_to_list(word, acc)
    end
  end

  defp add_initial(word, _locale, initial_template, acc) do
    word
    |> String.first()
    |> Cldr.Substitution.substitute(initial_template)
    |> add_to_list(acc)
  end

  defp add_to_list(element, list) do
    [element | list]
  end

  # TODO Is this correct?
  # Here we are just removing any diacritic on
  # a letter which seems to match the test cases.

  defp monogram(word, %{cldr_locale_name: locale}) do
    monogram(word, locale)
  end

  defp monogram(word, :el) do
    word
    |> String.first()
    |> Unicode.unaccent()
  end

  defp monogram(word, _locale) do
    String.first(word)
  end

  # upacase, downcase and titlecase have specific
  # handling for greek and turkic languages.

  defp mode_from_locale(%{cldr_locale_name: locale}) do
    mode_from_locale(locale)
  end

  defp mode_from_locale(:el), do: :greek
  defp mode_from_locale(locale) when locale in @turkic_languages, do: :turkic
  defp mode_from_locale(_), do: :default

  #
  # Helpers
  #

  # Join multiple initials together when there are more
  # than one.

  defp join_initials([], _formats) do
    []
  end

  defp join_initials([first], _formats) do
    [first]
  end

  defp join_initials([first, second | rest], formats)
       when is_initial(first) and is_initial(second) do
    substitution = Cldr.Substitution.substitute([first, second], formats.initial_sequence)
    join_initials([substitution | rest], formats)
  end

  defp join_initials([first | rest], formats) do
    [first | join_initials(rest, formats)]
  end

  # Derive the name locale
  #
  # Construct the name script in the following way.
  #
  # 1. Iterate through the characters of the surname, then through the given name.
  #    a. Find the script of that character using the Script property.
  #    b. If the script is not Common, Inherited, nor Unknown, return that script as the name script
  # 2. If nothing is found during the iteration, return Zzzz (Unknown Script)
  #
  # Construct the name base language in the following way.
  #
  # 1. If the PersonName object can provide a name locale, return its language.
  # 2. Otherwise, find the maximal likely locale for the name script and return its base
  #    language (first subtag).
  #
  # Construct the name locale in the following way:
  #
  # 1. If the PersonName object can provide a name locale, return a locale formed from it by
  #    replacing its script by the name script.
  # 2. Otherwise, return the locale formed from the name base language plus name script.

  @doc false
  def derive_name_locale(%{locale: %Cldr.LanguageTag{} = name_locale} = name, _formatting_locale) do
    name_script = dominant_script(name)

    if name_locale.script == name_script do
      {:ok, name_locale}
    else
      locale_name =
        Cldr.Locale.locale_name_from(name_locale.language, name_script, name_locale.territory, [])

      Cldr.validate_locale(locale_name, name_locale.backend)
    end
  end

  def derive_name_locale(%{locale: nil} = name, formatting_locale) do
    name_script = dominant_script(name)

    case find_likely_locale(name_script, formatting_locale.backend) do
      {:ok, name_locale} when not is_nil(name_locale) -> {:ok, name_locale}
      _ -> {:error, "No locale resolved for script #{inspect(name_script)}"}
    end
  end

  # Derive the formatting locale
  #
  #  Let the full formatting locale be the maximal likely locale for the formatter's locale. The
  #  formatting base language is the base language (first subtag) of the full formatting locale,
  #  and the formatting script is the script code of the full formatting locale.
  #
  #  Switch the formatting locale if necessary
  #
  #  A few script values represent a set of scripts, such as Jpan = {Hani, Kana, Hira}. Two script
  #  codes are said to match when they are either identical, or one represents a set which contains
  #  the other, or they both represent sets which intersect. For example, Hani and Jpan match,
  #  because {Hani, Kana, Hira} contains Hani.
  #
  #  If the name script doesn't match the formatting script:
  #
  #    1. If the name locale has name formatting data, then set the formatting locale to the name
  #       locale.
  #
  #    2. Otherwise, set the formatting locale to the maximal likely locale for the the locale
  #.      formed from und, plus the name script plus the region of the nameLocale.
  #
  #    For example, when a Hindi (Devanagari) formatter is called upon to format a name object that
  #    has the locale Ukrainian (Cyrillic):
  #
  #    *  If the name is written with Cyrillic letters, under the covers a Ukrainian (Cyrillic)
  #       formatter should be instantiated and used to format that name.
  #
  #    *  If the name is written in Greek letters, then under the covers a Greek (Greek-script)
  #       formatter should be instantiated and used to format.
  #
  #  To determine whether there is name formatting data for a locale, get the values for each of
  #  the following paths. If at least one of them doesn’t inherit their value from root, then the
  #  locale has name formatting data.

  def derive_formatting_locale(name, formatting_locale, name_locale) do
    cond do
      considered_the_same_script?(formatting_locale.script, name_locale.script) ->
        {:ok, formatting_locale}

      dominant_script(name) == name_locale.script ->
        {:ok, name_locale}

      true ->
        name_script = dominant_script(name)
        find_likely_locale(name_script, name_locale.territory, formatting_locale.backend)
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

  defp find_likely_locale(script, backend) do
    root_language = Cldr.Locale.root_language()
    likely_locale = Cldr.Locale.likely_subtags(root_language, script, nil, [])
    likely_locale && Cldr.Locale.canonical_language_tag(likely_locale, backend)
  end

  defp find_likely_locale(script, territory, backend) do
    root_language = Cldr.Locale.root_language()
    likely_locale = Cldr.Locale.likely_subtags(root_language, script, territory, [])
    likely_locale && Cldr.Locale.canonical_language_tag(likely_locale, backend)
  end

  @doc false
  def formats(formatting_locale, backend) do
    backend = Module.concat(backend, PersonName)
    formats = backend.formats_for(formatting_locale) || backend.formats_for(:und)
    {:ok, formats}
  end

  @doc false
  def determine_name_order(name, name_locale, backend, options) do
    language = name_locale.language
    backend = Module.concat(backend, PersonName)
    locale_order = backend.locale_order(name_locale) || backend.locale_order(:und)

    order =
      options[:order] || name.preferred_order || locale_order[language] || locale_order["und"] ||
        @default_order

    {:ok, Keyword.put(options, :order, order)}
  end

  @doc false
  def select_format(name, formats, options) do
    keys = [:person_name, options[:order], options[:format], options[:usage], options[:formality]]

    case get_in(formats, keys) do
      nil ->
        {:error, "No format found for options #{inspect(options)}"}

      format_list ->
        format = choose_format(name, format_list)
        {:ok, format}
    end
  end

  # Choose a namePattern
  # https://www.unicode.org/reports/tr35/tr35-personNames.html#choose-a-namepattern
  #
  # To format a name, the fields in a namePattern are replaced with fields fetched from the
  # PersonName Data Interface. The personName element can contain multiple namePattern elements.
  # Choose one based on the fields in the input PersonName object that are populated:
  #
  # Find the set of patterns with the most populated fields.
  #   If there is just one element in that set, use it.
  #   Otherwise, among that set, find the set of patterns with the fewest unpopulated fields.
  #   If there is just one element in that set, use it.
  #   Otherwise, take the pattern that is alphabetically least. (This step should rarely happen,
  #   and is only for producing a determinant result.)
  #
  # For example:
  #
  # Pattern A has 12 fields total, pattern B has 10 fields total, and pattern C has 8 fields total.
  # Both patterns A and B can be populated with 7 fields from the input PersonName object, pattern
  # C can be populated with only 3 fields from the input PersonName object.
  # Pattern C is discarded, because it has the least number of populated name fields.
  # Out of the remaining patterns A and B, pattern B wins, because it has only 3 unpopulated fields
  # compared to pattern A.

  # Only one format (most common) so return it.
  defp choose_format(_name, [{_priority, format}]) do
    format
  end

  # Score each format and arrange it in an order
  # such that term sorting produces the required
  # format.

  defp choose_format(name, formats) do
    {_populated, _unpopulated, _priority, format} =
      Enum.reduce(formats, [], fn {priority, format}, acc ->
        {fields, populated} = score(name, format)
        unpopulated = fields - populated

        [{-populated, unpopulated, priority, format} | acc]
      end)
      |> Enum.sort(:asc)
      |> hd()

    format
  end

  # Return the number fields present (they are a binary) and
  # the number of fields in the format.

  @doc false
  def score(name, format) do
    Enum.reduce(format, {0, 0}, fn
      field, {fields, populated} when is_binary(field) ->
        {fields, populated}

      field, {fields, populated} ->
        fields = fields + 1
        if filled?(field, name), do: {fields, populated + 1}, else: {fields, populated}
    end)
  end

  defp filled?([:title | _], %{title: title}),
    do: is_binary(title)
  defp filled?([:given2 | _], %{other_given_names: other_given_names}),
    do: is_binary(other_given_names)
  defp filled?([:given, :informal | _], name),
    do: is_binary(name.informal_given_name) || is_binary(name.given_name)
  defp filled?([:given | _], %{given_name: given_name}),
    do: is_binary(given_name)
  defp filled?([:surname, :prefix | _], %{surname_prefix: surname_prefix}),
    do: is_binary(surname_prefix)
  defp filled?([:surname | _], %{surname: surname}),
    do: is_binary(surname)
  defp filled?([:surname2 | _], %{other_surnames: other_surnames}),
    do: is_binary(other_surnames)
  defp filled?([:generation | _], %{generation: generation}),
    do: is_binary(generation)
  defp filled?([:credentials | _], %{credentials: credentials}),
    do: is_binary(credentials)

end