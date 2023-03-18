require Cldr.PersonName.Backend

defmodule MyApp.Cldr do
  use Cldr,
    default_locale: "en",
    locales: ["und", "de", "fr", "zh", "en", "bs", "pl", "ru", "th", "he", "da"],
    providers: [Cldr.PersonName]
end
