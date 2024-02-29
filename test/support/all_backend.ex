defmodule AllBackend.Cldr do
  use Cldr,
    locales: :all,
    default_locale: "en",
    providers: [Cldr.PersonName]
end
