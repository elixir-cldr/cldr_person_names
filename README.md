# Cldr for Formatting Person Names

![Build status](https://github.com/elixir-cldr/cldr_person_names/actions/workflows/ci.yml/badge.svg)
[![Hex.pm](https://img.shields.io/hexpm/v/ex_cldr_person_names.svg)](https://hex.pm/packages/ex_cldr_person_names)
[![Hex.pm](https://img.shields.io/hexpm/dw/ex_cldr_person_names.svg?)](https://hex.pm/packages/ex_cldr_person_names)
[![Hex.pm](https://img.shields.io/hexpm/dt/ex_cldr_person_names.svg?)](https://hex.pm/packages/ex_cldr_person_names)
[![Hex.pm](https://img.shields.io/hexpm/l/ex_cldr_person_names.svg)](https://hex.pm/packages/ex_cldr_person_names)

## Introduction and Getting Started

`ex_cldr_person_names` is an add-on library for [ex_cldr](https://hex.pm/packages/ex_cldr) that provides localised formatting for peoples' names.  It follows the [CLDR Person Names](https://www.unicode.org/reports/tr35/tr35-personNames.html) specification.

### Configuration

A backend module must be defined into which the public API and the [CLDR](https://cldr.unicode.org) data is compiled.  See the [ex_cldr documentation](https://hexdocs.pm/ex_cldr/readme.html) for further information on configuration.

In the following examples we assume the presence of a module called `MyApp.Cldr` defined as:

```elixir
defmodule MyApp.Cldr do
  use Cldr,
    locales: ["en", "fr"],
    default_locale: "en",
    providers: [Cldr.PersonName]
end
```

Note the `:provider` configuration key which is required to include `Cldr.PersonName` in order for person name formatting to be configured for this backend.

### Installation

Note that `:ex_cldr_person_names` requires Elixir 1.12 or later.

Add `ex_cldr_person_names` as a dependency to your `mix` project:

    defp deps do
      [
        {:ex_cldr_person_names, "~> 0.1"}
      ]
    end

then retrieve `ex_cldr_person_names` from [hex](https://hex.pm/packages/ex_cldr_person_names):

    mix deps.get
    mix deps.compile

## Presentations

* Launch presentation at the [Elixir Sydney Meetup](https://www.youtube.com/watch?v=pBR-n_dA3lo) in February 2024.
* The slides from the launch presetnation are available in [Powerpoint format](https://github.com/elixir-cldr/cldr_person_names/raw/main/presentations/Person%20Name%20Formatting.pptx) and [PDF format](https://github.com/elixir-cldr/cldr_person_names/raw/main/presentations/Person%20Name%20Formatting.pdf)

The livebook used at the launch presentation is also available.

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2Felixir-cldr%2Fcldr_person_names%2Fmain%2Flivebooks%2Fperson_name_formatting_explorer.livemd)

## Why Person Name Formatting? 
<!-- Split --->
`ex_cldr_person_names` provides formatting for person names, such as John Smith or 宮崎駿 based upon the [CLDR Person Names](https://www.unicode.org/reports/tr35/tr35-personNames.html) specification. These use patterns to show how a name object (for example, from a database) should be formatted for a particular locale. Name data has fields for the parts of people’s names, such as a given name field with a value of “Maria”, and a surname field value of “Schmidt”.

There is a wide variety in the way that people’s names appear in different languages.

* People may have a different number of names, depending on their culture—they might have only one name (“Zendaya”), two (“Albert Einstein”), or three or more.
* People may have multiple words in a particular name field, eg “Mary Beth” as a given name, or “van Berg” as a surname.
* Some languages, such as Spanish, have two surnames (where each can be composed of multiple words).
* The ordering of name fields can be different across languages, as well as the spacing (or lack thereof) and punctuation.
* Name formatting needs to be adapted to different circumstances, such as a need to be presented shorter or longer; formal or informal context; or when talking about someone, or talking to someone, or as a monogram (JFK).

The `ex_cldr_person_names` functionality is targeted at formatting names for typical usage on computers (e.g. contact names, automated greetings, etc.), rather than being designed for special circumstances or protocol, such addressing royalty. However, the structure may be enhanced in the future when it becomes clear that additional features are needed for some languages.

### Not in scope

The following features are currently out of scope for Person Names formating:

* Grammatical inflection of formatted names.
* Context-specific cultural aspects, such as when to use “-san” vs “-sama” when addressing a Japanese person.
* Providing locale-specific lists of titles, generation terms, and credentials for use in pull-down menus or validation (Mr, Ms., Mx., Dr., Jr., M.D., etc.).
* Validation of input, such as which fields are required, and what characters are allowed.
* Combining alternative names, such as multicultural names in Hong Kong "Jackie Chan Kong-Sang”, or ‘Dwayne “The Rock” Johnson’.
* More than two levels of formality for names.
* Parsing of names. 
  * Parsing of name strings into specific name parts such as given and given2. A name like "Mary Beth Estrella" could conceivably be any of the following.

  | Given Name	| Other Given Names | Surname       | Other Surnames  |
  | ----------  | ----------------- | -------       | --------------  |
  | Mary	      | Beth	            | Estrella      |                 |	
  | Mary Beth		|                   | Estrella      |                 |	
  | Mary		    |                   | Beth Estrella	|                 |
  | Mary		    |                   | Beth	        | Estrella        |

  * Parsing out the other components of a name in a string, such as surname prefixes (Tussenvoegsel in Dutch).
  
## Structure of a Person Name

Person name formatting depends on data supplied by a `t:Cldr.PersonName.t/0` data structure. A `Cldr.PersonName` behaviour and a `Cldr.PersonName.Format` protocol are provided to support easy integration with existing data structures.

The `t:Cldr.PersonName.t/0` struct is composed of one or more name parts:

* `title` - a string that represents one or more honorifics or titles, such as “Mr.”, or “Herr Doctor”.
* `given_name` - usually a name given to someone that is not passed to a person by way of parentage.
* `informal_given_name` - usually either a nickname or a shortened form of the given name that is used to address a person informally.
* `other_given_names` - name or names that may appear between the first given name string and the surname. In the West, this may be a middle name, in Slavic regions it may be a patronymic name, and in parts of the Middle East, it may be the nasab (نسب) or series of patronymics.
* `surname_prefix` - in some languages the surname may have a prefix that needs to be treated differently, for example “van den Berg”.
* `surname` - usually the family name passed to a person that indicates their family, tribe, or community. In most Western languages, this is known as the last name.
* `other_surnames` - in some cultures, both the parent’s surnames are used and need to be handled separately for formatting in different contexts.
* `generation` - a string that represents a generation marker, such as “Jr.” or “III”.
* `credentials` - a string that represents one or more credentials or accreditations, such as “M.D.”, or “MBA”.
* `locale` - defines the `t.Cldr.LanguageTag.t/0` of a name. This allows different formatting of a name depending on whether it is being formatted for its native locale, or for a different locale.
* `preferred_order` - an atom indicating the preferred name order for this name. The valid values are `:given_first`, `:surname_first`, `:sorting`. By default, `ex_cldr_person_names` will derive the name order based upon the name's locale and the formatting locale.

**At mininum, a `given_name` is required. All other name attributes are optional**.

## Integration with Existing Data

Its clear that existing person name data isn't going to be neatly structured in a `t:Cldr.PersonName.t/0`. `ex_cldr_person_names` provides two mechanisms to integrate existing data:

* The `Cldr.PersonName` behaviour can be used when the developer has control over the data structure, and the data structure is an Elixir `struct`. This is the recommended approach when the developer has control over the struct module. In this case, [callbacks](Cldr.PersonName.html#callbacks) can be implemented for the `struct` that return the person name data to the formatter. The formatter implementation will call `Cldr.PersonName.cast_to_person_name/1` using the callbacks. 

* The `Cldr.PersonName.Format` protocol is useful when the developer has no control over the existing data structure. Therefore the `Cldr.PesonName.Format.to_string/2` function can be called and the protocol implementation is expected to craft a structure compatible with - or actually is - a `t:Cldr.PersonName.t/0` struct, and then calls the `Cldr.PersonName.to_string/2` function.  Since `t:Cldr.PersonName.t/0` implements the `Cldr.PersonName.Format` protocol, `Cldr.PersonName.Format.to_string/2` can be used consistently throughout an application if preferred.
