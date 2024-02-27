defmodule Cldr.Lists.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :ex_cldr_person_names,
      version: @version,
      docs: docs(),
      elixir: "~> 1.10",
      name: "Cldr Lists",
      source_url: "https://github.com/elixir-cldr/cldr_person_names",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore_warnings",
        plt_add_apps: ~w(inets jason mix)a
      ]
    ]
  end

  defp description do
    """
    Person name formatting functions for the Common Locale Data Repository (CLDR)
    package ex_cldr.
    """
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # {:ex_cldr, "~> 2.38"},
      {:ex_cldr, path: "../cldr", override: true},

      {:unicode, "~> 1.16"},
      {:unicode_string, "~> 1.0"},
      {:ex_doc, "~> 0.18", optional: true, runtime: false},
      {:jason, "~> 1.0", optional: true},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache-2.0"],
      links: links(),
      files: [
        "lib",
        "config",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end

  def docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "LICENSE.md"],
      logo: "logo.png",
      formatters: ["html"],
      skip_undefined_reference_warnings_on: ["changelog", "CHANGELOG.md"]
    ]
  end

  def links do
    %{
      "GitHub" => "https://github.com/elixir-cldr/cldr_person_names",
      "Readme" => "https://github.com/elixir-cldr/cldr_person_names/blob/v#{@version}/README.md",
      "Changelog" =>
        "https://github.com/elixir-cldr/cldr_person_names/blob/v#{@version}/CHANGELOG.md"
    }
  end

  defp elixirc_paths(:test), do: ["lib", "mix", "test"]
  defp elixirc_paths(:dev), do: ["lib", "mix"]
  defp elixirc_paths(_), do: ["lib"]
end
