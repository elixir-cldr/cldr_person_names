require Cldr.PersonName.Backend

defmodule MyApp.Cldr do
  use Cldr,
    default_locale: "en",
    locales: [
      "und",
      "de",
      "fr",
      "zh",
      "en",
      "bs",
      "pl",
      "ru",
      "th",
      "he",
      "da",
      "ja",
      "ko",
      "es",
      "it",
      "en-AU",
      "en-CA",
      "en-GB",
      "en-IN",
      "pt",
      "pt-PT",
      "nl",
      "af",
      "fi",
      "id",
      "es-US",
      "es-MX",
      "es-419",
      "cs",
      "th",
      "lo",
      "my",
      "ca",
      "el",
      "pcm"
    ],
    providers: [Cldr.PersonName]
end
