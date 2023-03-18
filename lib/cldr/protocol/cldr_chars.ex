defimpl Cldr.Chars, for: Cldr.PersonName do
  def to_string(name) do
    locale = Cldr.get_locale()
    Cldr.PersonName.to_string!(name, locale: locale, backend: locale.backend)
  end
end