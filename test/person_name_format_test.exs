defmodule Cldr.PersonName.FormatTest do
  use ExUnit.Case, async: true

  @tests 1..500
  @test_locales [
    :en,
    :fr,
    :de,
    :es,
    :it,
    :pl,
    :ru,
    :th,
    :da,
    :en_AU,
    :en_CA,
    :en_GB,
    :en_IN,
    :pt,
    :pt_PT,
    :ja,
    :he,
    :zh,
    :ko,
    :af,
    :fi,
    :id,
    :am,
    :ar,
    # :as,
    :az,
    :be,
    :bg,
    :bn,
    :bs,
    :ca,
    :chr,
    :cs,
    :cy
  ]

  # for test <- Cldr.PersonName.TestData.parse_all_locales() do
  for test <- Cldr.PersonName.TestData.parse_locales(@test_locales),
      test.line in @tests && !Cldr.PersonName.TestData.tests_that_might_be_bugs(test) do
    with {:ok, test_locale} <- AllBackend.Cldr.validate_locale(test.locale),
         {:ok, name_locale} <- AllBackend.Cldr.validate_locale(test.name.locale) do
      name = Map.put(test.name, :locale, name_locale)
      params = test.params ++ [locale: test_locale]

      test "#{inspect(test.locale)}@#{test.line} with params #{inspect(test.params)} formats to #{inspect(test.expected_result)}" do
        assert {:ok, unquote(test.expected_result)} =
                 Cldr.PersonName.to_string(
                   unquote(Macro.escape(name)),
                   unquote(Macro.escape(params))
                 )
      end
    end
  end
end
