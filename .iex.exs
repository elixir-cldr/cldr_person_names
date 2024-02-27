require Cldr
require MyApp.Cldr

alias Cldr.PersonName
import Cldr.LanguageTag.Sigil, only: :macros

{:ok, en_aq} = Cldr.validate_locale("en-AQ", MyApp.Cldr)
{:ok, ja_aq} = Cldr.validate_locale("ja-AQ", MyApp.Cldr)

# name ; given; Mary Sue
# name ; given2; Hamish
# name ; surname; Watson
# name ; locale; en_AQ

mary = %PersonName{given_name: "Mary Sue", other_given_names: "Hamish", surname: "Watson", locale: en_aq}

# name ; given; Käthe
# name ; surname; Müller
# name ; locale; ja_AQ

kathe = %PersonName{given_name: "Käthe", surname: "Müller", locale: ja_aq}