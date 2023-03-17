# defimpl Cldr.Chars, for: PersonName do
#   def to_string(list) do
#     locale = Cldr.get_locale()
#     Cldr.PersonName.to_string!(list, locale.backend, locale: locale)
#   end
# end