defmodule CldrPersonNamesTest do
  use ExUnit.Case
  doctest CldrPersonNames

  test "greets the world" do
    assert CldrPersonNames.hello() == :world
  end
end
