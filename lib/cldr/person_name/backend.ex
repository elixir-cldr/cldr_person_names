defmodule Cldr.PersonName.Backend do
  def define_person_name_module(config) do
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
        @spec to_iodata(PersonName.t(), PersonName.options()) ::
                {:ok, String.t()} | {:error, {module(), String.t()}}

        def to_iodata(%PersonName{} = name, options \\ []) do
          options = Keyword.put(options, :backend, unquote(backend))
          PersonName.to_iodata(name, options)
        end

        @doc """
        Formats a person name using `to_string/2` but raises if there is
        an error.

        ## Examples

        """
        @spec to_iodata!(Cldr.PersonName.t(), Keyword.t()) :: String.t() | no_return()
        def to_iodata!(list, options \\ []) do
          case to_iodata(list, options) do
            {:error, {exception, message}} ->
              raise exception, message

            {:ok, string} ->
              string
          end
        end

        for locale_name <- Locale.Loader.known_locale_names(config) do
          locale_data =
            locale_name
            |> Locale.Loader.get_locale(config)
            |> Map.get(:person_names)

          formats =
            locale_data
            |> Map.delete(:given_first)
            |> Map.delete(:surname_first)
            |> Cldr.Map.deep_map(fn {k, v} -> {k, Substitution.parse(v)} end,
              only: [:initial, :initial_sequence]
            )
            |> Cldr.Map.deep_map(
              fn {type, formats} ->
                formats =
                  Enum.map(formats, fn format ->
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
                  end)

                {type, formats}
              end,
              only: [:formal, :informal]
            )
            |> Cldr.Map.atomize_values(only: [:length, :formality])
            |> Map.new()

          given_order =
            locale_data
            |> Map.get(:given_first)
            |> Enum.map(fn language -> {language, :given_first} end)

          surname_order =
            locale_data
            |> Map.get(:surname_first)
            |> Enum.map(fn language -> {language, :surname_first} end)

          locale_order = Map.new(given_order ++ surname_order)
          foreign_space_replacement = Map.get(locale_data, :foreign_space_replacement)
          native_space_replacement = Map.get(locale_data, :native_space_replacement)

          def formats_for(unquote(locale_name)) do
            unquote(Macro.escape(formats))
          end

          def locale_order(unquote(locale_name)) do
            unquote(Macro.escape(locale_order))
          end

          def native_space_replacement(unquote(locale_name)) do
            unquote(native_space_replacement)
          end

          def foreign_space_replacement(unquote(locale_name)) do
            unquote(foreign_space_replacement)
          end
        end

        def formats_for(%Cldr.LanguageTag{cldr_locale_name: cldr_locale_name}) do
          formats_for(cldr_locale_name)
        end

        def formats_for(locale) when is_binary(locale) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale) do
            formats_for(locale)
          end
        end

        def formats_for(locale) do
          {:error, "No person name data found for #{inspect(locale)}"}
        end

        def locale_order(%Cldr.LanguageTag{cldr_locale_name: cldr_locale_name}) do
          locale_order(cldr_locale_name)
        end

        def locale_order(locale) do
          {:error, "No locale order data found for #{inspect(locale)}"}
        end
      end
    end
  end
end
