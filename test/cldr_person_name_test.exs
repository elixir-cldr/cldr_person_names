defmodule Cldr.PersonName.Test do
  use ExUnit.Case, async: true

  for {name, person_name} <- Cldr.PersonName.Names.names() do
    person_name = Macro.escape(person_name)

    test "Cldr.PersonName.new/1 for #{name}" do
      attributes = unquote(person_name) |> Map.to_list() |> Keyword.delete(:__struct__)
      assert {:ok, _person_name} = Cldr.PersonName.new(attributes)
    end
  end

  describe "to_string/1" do
    test "works" do
      {:ok, %Cldr.PersonName{} = name} = Cldr.PersonName.new(given_name: "James")
      assert is_binary(Cldr.PersonName.to_string(name))
    end
  end
end
