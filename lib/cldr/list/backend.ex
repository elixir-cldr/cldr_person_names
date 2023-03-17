defmodule Cldr.PersonName.Backend do
  def define_backend_module(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [module: module, backend: backend, config: config] do
      defmodule PersonName do
        @moduledoc false
        if Cldr.Config.include_module_docs?(config.generate_docs) do
          @moduledoc """
          Cldr backend module that formats person names.

          """
        end

        alias Cldr.PersonName
        alias Cldr.Substitution
        alias Cldr.Locale

        @doc """
        Formats a person name.

        ## Arguments


        ## Options


        ## Examples


        """
        @spec to_string(PersonName.t(), PersonName.options()) ::
                {:ok, String.t()} | {:error, {module(), String.t()}}

        def to_string(%PersonName{} = name, options \\ []) do
          options = Keyword.put(options, :backend, __MODULE__)
          PersonName.to_string(name, options)
        end

        @doc """
        Formats a person name using `to_string/2` but raises if there is
        an error.

        ## Examples

        """
        @spec to_string!(Cldr.PersonName.t(), Keyword.t()) :: String.t() | no_return()
        def to_string!(list, options \\ []) do
          case to_string(list, options) do
            {:error, {exception, message}} ->
              raise exception, message

            {:ok, string} ->
              string
          end
        end

        for locale_name <- Locale.Loader.known_locale_names(config) do
          formats =
            locale_name
            |> Locale.Loader.get_locale(config)
            |> Map.get(:person_names)
            |> Cldr.Map.deep_map(fn {k, v} -> {k, Substitution.parse(v)} end, only: [:initial, :initial_sequence])
            |> Cldr.Map.deep_map(fn {type, format} ->
              format =
                Enum.map(Regex.split(~r/{.*}/uU, format, trim: true, include_captures: true), fn
                  "{" <> field ->
                    field
                    |> String.trim_trailing("}")
                    |> String.split("-")
                    |> Enum.map(&Cldr.String.underscore/1)
                    |> Enum.map(&String.to_atom/1)

                  literal ->
                    literal
                end)
              {type, format}
            end, only: [:formal, :informal])
            |> Map.new()

          def formats_for(unquote(locale_name)) do
            {:ok, unquote(Macro.escape(formats))}
          end
        end

        def formats_for(%Cldr.LanguageTag{language: language}) do
          formats_for(language)
        end

        def formats_for(locale) do
          {:error, "No person name data"}
        end
      end
    end
  end
end