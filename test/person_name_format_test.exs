defmodule Cldr.PersonName.FormatTest do
  use ExUnit.Case, async: true

  @tests 1..1000

  @all_locales Cldr.PersonName.TestData.all_locales()

  @failing_locales [
    :as, :ca, :gl, :gu, :hi, :kn, :km, :he, :or, :si, :my, :te, :pa, :ml, :ne, :mr, :el, :ko
  ]

  @test_locales (@all_locales -- @failing_locales)

  # These all pass tests
  @test_locales [
    :en, :it, :de, :fr, :fr_CA, :da, :nl, :pt_PT,
    :zh, :zh_Hant, :zh_Hant_HK,
    :ja, :ko,
    :id, :lo, :th,
    :es, :es_MX, :es_419, :es_US
  ]

  @test_locales [
    :ca
  ]

  # @test_locales [
  #   :cs
  # ]

  # These are work in progress
  # @test_locales []

  for test <- Cldr.PersonName.TestData.parse_locales(@test_locales),
      test.line in @tests do
    with {:ok, test_locale} <- AllBackend.Cldr.validate_locale(test.locale),
         {:ok, name_locale} <- AllBackend.Cldr.validate_locale(test.name.locale) do
      name = Map.put(test.name, :locale, name_locale)
      params = test.params ++ [locale: test_locale]
      test_name = "#{test.locale}@#{test.line} with params #{inspect(test.params)}"

      test test_name do
        assert {:ok, unquote(test.expected_result)} =
                 Cldr.PersonName.to_string(
                   unquote(Macro.escape(name)),
                   unquote(Macro.escape(params))
                 )
      end
    end
  end
end
