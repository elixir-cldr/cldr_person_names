defmodule Cldr.PersonName.FormatTest do
  use ExUnit.Case, async: true

  @tests 1..1000

  @all_locales Cldr.PersonName.TestData.all_locales()

  @failing_locales [
    :gu, :hi, :hi_Latn, :km, :kn, :kok, :ml, :mr, :my, :ne, :or,
    :pa, :si, :ta, :te, :as,

    # Data error?
    :es_US
  ]

  @test_locales (@all_locales -- @failing_locales)

  # These all pass tests - 93 of them
  @test_locales [
    :am, :ar, :az, :be, :bg, :bn,
    :chr, :cs, :cy,
    :dsb,
    :en, :en_AU, :en_CA, :en_GB, :en_IN,
    :it, :de, :fr, :fr_CA, :da, :nl, :pt_PT, :ca, :cs,
    :el, :et, :eu, :fa, :fi, :ga, :gd, :gl,
    :ha, :ha_NE, :he, :hr, :hsb, :hu, :hy,
    :ig, :is, :jv, :ka, :kk, :ko, :ky,
    :lo, :lv, :mk, :mn, :ms, :nn, :no,
    :pl, :ps, :pt, :qu, :ro, :ru,
    :sc, :sd, :sk, :sl, :so, :sq,
    :sr_Cyrl_BA, :sr_Latn_BA, :sr_Latn, :sr,
    :sv, :sw_KE, :sw,
    :tg, :ti, :tk, :tr,
    :uk, :ur, :uz, :vi,
    :wo, :yo_BJ, :zu,
    :zh, :zh_Hant, :zh_Hant_HK, :yue_Hans, :yue,
    :ja, :ko,
    :id, :lo, :th,
    :es, :es_MX, :es_419
  ]
  |> Enum.uniq()

  # These are work in progress
  @test_locales [
    :gu, :hi, :hi_Latn, :km, :kn, :kok, :ml, :mr, :my, :ne, :or,
    :pa, :si, :ta, :te, :as,

    # Data error?
    :es_US
  ]

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
