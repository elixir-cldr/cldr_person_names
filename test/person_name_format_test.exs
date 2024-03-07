defmodule Cldr.PersonName.FormatTest do
  use ExUnit.Case, async: true

  @tests 1..500
  @all_locales Cldr.PersonName.TestData.all_locales()

  @failing_locales [:as, :ca, :cs, :es, :es_419, :es_MX, :es_US, :gl, :gu, :hi, :kn, :km, :he]

  @tests_not_compiling [:ky, :kok, :zu]

  @test_locales ((@all_locales -- @failing_locales) --  @tests_not_compiling)
  |> Enum.take(45)

  for test <- Cldr.PersonName.TestData.parse_locales(@test_locales),
      test.line in @tests do
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
