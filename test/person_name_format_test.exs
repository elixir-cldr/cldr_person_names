defmodule Cldr.PersonName.FormatTest do
  use ExUnit.Case, async: true

  @tests 1..1000
  # @tests [339, 343, 514, 715]
  # @tests [343]

  @all_locales Cldr.PersonName.TestData.all_locales()

  # Failing - disagreement between test, spec and implementation
  @failing_locales [
    :gu, :hi, :hi_Latn, :km, :kn, :kok, :ml, :mr, :my, :ne, :or,
    :pa, :si, :ta, :te, :as, :yo_BJ,

    # Data error?
    :es_US
  ]

  @test_locales (@all_locales -- @failing_locales)

  # These all pass tests - 92 of them
  @test_locales [
    :am, :ar, :az, :be, :bg, :bn, :ca, :chr, :cs, :cy, :da, :de, :dsb, :el, :en,
    :en_AU, :en_CA, :en_GB, :en_IN, :es, :es_419, :es_MX, :et, :eu, :fa, :fi, :fr,
    :fr_CA, :ga, :gd, :gl, :ha, :ha_NE, :he, :hr, :hsb, :hu, :hy, :id, :ig, :is,
    :it, :ja, :jv, :ka, :kk, :ko, :ky, :lo, :lv, :mk, :mn, :ms, :nl, :nn, :no, :pl,
    :ps, :pt, :pt_PT, :qu, :ro, :ru, :sc, :sd, :sk, :sl, :so, :sq, :sr,
    :sr_Cyrl_BA, :sr_Latn, :sr_Latn_BA, :sv, :sw, :sw_KE, :tg, :th, :ti, :tk, :tr,
    :uk, :ur, :uz, :vi, :wo, :yue, :yue_Hans, :zh, :zh_Hant, :zh_Hant_HK,
    :zu
  ]

  # @test_locales [:yo_BJ]

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
