defmodule Cldr.PersonName.CharsTest do
  use ExUnit.Case, async: true

  test "Cldr.to_string/1 on a person name" do
    string =
      Cldr.PersonName.Names.names()
      |> Map.get(:mary)
      |> Cldr.to_string()

    assert string == "Mary Sue"
  end

  test "Kernel.to_string/1 on a person name" do
    string =
      Cldr.PersonName.Names.names()
      |> Map.get(:mary)
      |> to_string()

    assert string == "Mary Sue"
  end

  for {name, person_name} <- Cldr.PersonName.Names.names() do
    person_name = Macro.escape(person_name)

    test "to_string/1 for #{name}" do
      attributes = unquote(person_name) |> Map.to_list() |> Keyword.delete(:__struct__)
      assert {:ok, person_name} = Cldr.PersonName.new(attributes)
      assert is_binary(to_string(person_name))
      assert is_binary(Cldr.to_string(person_name))
    end
  end
end
