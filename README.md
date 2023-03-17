# Cldr for People's Names
![Build Status](http://sweatbox.noexpectations.com.au:8080/buildStatus/icon?job=cldr_person_names)
[![Hex.pm](https://img.shields.io/hexpm/v/ex_cldr_person_names.svg)](https://hex.pm/packages/ex_cldr_person_names)
[![Hex.pm](https://img.shields.io/hexpm/dw/ex_cldr_person_names.svg?)](https://hex.pm/packages/ex_cldr_person_names)
[![Hex.pm](https://img.shields.io/hexpm/l/ex_cldr_person_names.svg)](https://hex.pm/packages/ex_cldr_person_names)

## Introduction and Getting Started

`ex_cldr_person_names` is an add-on library for [ex_cldr](https://hex.pm/packages/ex_cldr) that provides localisation and formatting for people's names.  It follows the [CLDR Person Names](https://www.unicode.org/reports/tr35/tr35-personNames.html) specification.

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

## Installation

Note that `:ex_cldr_person_names` requires Elixir 1.11 or later.

Add `ex_cldr_person_names` as a dependency to your `mix` project:

    defp deps do
      [
        {:ex_cldr_person_names, "~> 0.1"}
      ]
    end

then retrieve `ex_cldr_person_names` from [hex](https://hex.pm/packages/ex_cldr_person_names):

    mix deps.get
    mix deps.compile

## Public API & Examples


