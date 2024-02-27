defmodule Cldr.PersonName.FormatTest do
  use ExUnit.Case, async: true

  @tests 1..500

  #for test <- Cldr.PersonName.TestData.parse_all_locales() do
  for test <- Cldr.PersonName.TestData.parse("en"), test.line in @tests do
    with {:ok, test_locale} <- AllBackend.Cldr.validate_locale(test.locale),
        {:ok, name_locale} <- AllBackend.Cldr.validate_locale(test.name.locale) do
      name = Map.put(test.name, :locale, name_locale)

      test "##{test.line} in locale #{inspect test.locale} formats to #{inspect test.expected_result}" do
        assert {:ok, unquote(test.expected_result)} =
          Cldr.PersonName.to_string(unquote(Macro.escape(name)),
            unquote(Macro.escape(test.params ++ [locale: test_locale])))
      end
    end
  end

end