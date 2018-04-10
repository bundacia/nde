defmodule NDETest do
  use ExUnit.Case
  doctest NDE

  test "counter starts at 1" do
    assert NDE.Counter.inc == 1
  end
end
