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
end
