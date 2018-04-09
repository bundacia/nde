defmodule NDETest do
  use ExUnit.Case
  doctest NDE

  test "greets the world" do
    assert NDE.hello() == :world
  end
end
