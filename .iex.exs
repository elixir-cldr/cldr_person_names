require Cldr
require MyApp.Cldr

alias Cldr.PersonName
import Cldr.LanguageTag.Sigil, only: :macros

{:ok, en_aq} = Cldr.validate_locale("en-AQ", MyApp.Cldr)
{:ok, ja_aq} = Cldr.validate_locale("ja-AQ", MyApp.Cldr)
{:ok, fr_aq} = Cldr.validate_locale("fr-AQ", MyApp.Cldr)

# name ; given; Mary Sue
# name ; given2; Hamish
# name ; surname; Watson
# name ; locale; en_AQ

mary = %PersonName{given_name: "Mary Sue", other_given_names: "Hamish", surname: "Watson", locale: en_aq}

# name ; given; Käthe
# name ; surname; Müller
# name ; locale; ja_AQ

kathe = %PersonName{given_name: "Käthe", surname: "Müller", locale: ja_aq}

# name ; given; Irene
# name ; surname; Adler
# name ; locale; en_AQ

irene = %PersonName{given_name: "Irene", surname: "Adler", locale: en_aq}

# name ; given; Sinbad
# name ; locale; ja_AQ

sinbad = %PersonName{given_name: "Sinbad", locale: ja_aq}

# nativeG
# name ; given; Zendaya
# name ; locale; en_AQ

zendaya = %PersonName{given_name: "Zendaya", locale: en_aq}

# nativeFull
# name ; title; M.
# name ; given; Jean-Nicolas
# name ; given-informal; Nico
# name ; given2; Louis Marcel
# name ; surname-prefix; de
# name ; surname-core; Bouchart
# name ; generation; fils
# name ; locale; fr_AQ

jn = %PersonName{
  given_name: "Jean-Nicolas",
  informal_given_name: "Nico",
  other_given_names: "Louis Marcel",
  surname_prefix: "de",
  surname: "Bouchart",
  generation: "fils",
  locale: fr_aq
}

# nativeG
# name ; given; Adèle
# name ; locale; fr_AQ

adele = %PersonName{given_name: "Adèle", locale: fr_aq}