defmodule NDE.TrapAndPrint do
  def trap_and_print do
    Process.flag :trap_exit, true
    loop()
  end

  def loop() do
    receive do
      msg ->
        IO.puts "GOT MSG: #{inspect msg}"
        loop()
    end
  end
end
