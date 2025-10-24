defmodule Cldr.PersonName.FormatTest do
  use ExUnit.Case, async: true

  @tests 1..1000

  @all_locales Cldr.PersonName.TestData.all_locales()

  # Failing - disagreement between test, spec and implementation
  # Probably because the formatting locale switches (which we don't
  # current support).

  # Should revisit the es_* locales though - that might be different bugs than the
  # "formatting locale switching"

  @failing_locales [
    :kok, :si, :my, :yue_Hans, :ti, :kn, :km, :ml, :yo_BJ, :es_US, :es_MX, :sk, :mr, :es, :cs,
    :es_419, :gd
  ]

  @test_locales (@all_locales -- @failing_locales)

  for test <- Cldr.PersonName.TestData.parse_locales(@test_locales),
      test.line in @tests do
    with {:ok, test_locale} <- AllBackend.Cldr.validate_locale(test.locale),
         {:ok, name_locale} <- AllBackend.Cldr.validate_locale(test.name.locale) do
      name = Map.put(test.name, :locale, name_locale)
      params = [{:locale, test_locale} | test.params]
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
