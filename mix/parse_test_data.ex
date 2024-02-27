defmodule Cldr.PersonName.TestData do
  @test_data_dir "./test/support/person_name_test_data"

  defstruct line: nil,
            name: %Cldr.PersonName{},
            expected_result: nil,
            locale: nil,
            params: []

  def parse_all_locales do
    @test_data_dir
    |> Path.join("/*.txt")
    |> Path.wildcard()
    |> Enum.map(&Path.basename(&1, ".txt"))
    |> Enum.map(&parse/1)
    |> List.flatten()
    |> Enum.reject(&is_nil(&1.line))
  end

  def parse(locale) do
    with {:ok, data} <- File.read(Path.join(@test_data_dir, "/#{locale}.txt")) do
      data
      |> String.split("\n")
      |> Enum.with_index(fn element, index -> {index, element} end)
      |> parse_lines(locale, [reset(locale)])
    end
  end

  def parse_lines([{_i1, "name" <> _comment} = line | rest], locale, acc) do
    acc = parse_line(line, locale, acc)
    parse_lines(rest, locale, acc)
  end

  def parse_lines([{_i1, "expectedResult" <> _rest} = line | rest], locale, acc) do
    acc = parse_line(line, locale, acc)
    parse_lines(rest, locale, acc)
  end

  def parse_lines([{_i1, "parameters" <> _rest} = line | rest], locale, acc) do
    acc = parse_line(line, locale, acc)
    parse_lines(rest, locale, acc)
  end

  def parse_lines([{_i1, "endName" <> _rest} | rest], locale, acc) do
    parse_lines(rest, locale, [reset(locale) | acc])
  end

  def parse_lines([_other | rest], locale, acc) do
    parse_lines(rest, locale, acc)
  end

  def parse_lines([], _locale, acc) do
    acc
  end

  defp parse_line({_test, <<"name", _::binary>> = line}, _locale, [current | rest]) do
    [_key, field, value] = split_line(line)
    name = Map.put(current.name, field_name(field), value)
    [%{current | name: name} | rest]
  end

  defp parse_line({_test, <<"expectedResult", _::binary>> = line}, _locale, [current | rest]) do
    [_key, value] = split_line(line)

    # Its nil after a reset which happens at the start of the file
    # or when endName is found
    if is_nil(current.expected_result) do
      [%{current | expected_result: value} | rest]
    else
      [%{current | expected_result: value, params: nil}, current | rest]
    end
  end

  defp parse_line({test, <<"parameters", _::binary>> = line}, _locale, [current | rest]) do
    [_key, order, format, usage, formality] =
      line
      |> split_line()
      |> normalize_params()

    params = [
      order: order,
      format: format,
      usage: usage,
      formality: formality
    ]
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)

    # Its nil when either a reset at start or endName or
    # when a new expectedResult is found
    if is_nil(current.params) do
      [%{current | line: test + 1, params: params} | rest]
    else
      [%{current | line: test + 1, params: params}, current | rest]
    end
  end

  defp reset(locale) do
    %__MODULE__{locale: locale}
  end

  defp normalize_params(elems) do
    Enum.map(elems, fn
      "none" -> nil
      other -> other |> Macro.underscore() |> String.to_atom()
    end)
  end

  defp split_line(line) do
    line
    |> String.split(";")
    |> Enum.map(&String.trim/1)
  end

  defp field_name("title"), do: :title

  defp field_name("given"), do: :given_name
  defp field_name("given-informal"), do: :informal_given_name
  defp field_name("given2"), do: :other_given_names

  defp field_name("surname"), do: :surname
  defp field_name("surname-core"), do: :surname
  defp field_name("surname-prefix"), do: :surname_prefix
  defp field_name("surname2"), do: :other_surnames

  defp field_name("generation"), do: :generation
  defp field_name("credentials"), do: :credentials
  defp field_name("locale"), do: :locale
end
