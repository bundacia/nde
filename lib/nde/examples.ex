defmodule NDE.Examples do
  @moduledoc """
  iex(32)> a = spawn NDE.Examples, :a, [:parent, :quit]
  #PID<0.13316.0>
  a: (#PID<0.13316.0>) Ending loop
  b: (#PID<0.13317.0>) got msg: {:EXIT, #PID<0.13316.0>, :normal}

  iex(33)> a = spawn NDE.Examples, :a, [:child, :quit]
  #PID<0.13319.0>
  b: (#PID<0.13320.0>) Ending loop
  a: (#PID<0.13319.0>) got msg: {:EXIT, #PID<0.13320.0>, :normal}

  iex(43)> a = spawn NDE.Examples, :a, [:child, :exception]
  #PID<0.13373.0>
  b: (#PID<0.13374.0>) Rasing exception
  a: (#PID<0.13373.0>) got msg: {:EXIT, #PID<0.13374.0>, {%RuntimeError{message: "Goodbye World!"}, [{NDE.Examples, :loop, 1, [file: 'lib/nde/examples.ex', line: 30]}]}}
  09:49:05.495 [error] Process #PID<0.13374.0> raised an exception
  ** (RuntimeError) Goodbye World!
      (nde) lib/nde/examples.ex:30: NDE.Examples.loop/1

  iex(45)> a = spawn NDE.Examples, :a, [:parent, :exception]
  #PID<0.13377.0>
  a: (#PID<0.13377.0>) Rasing exception
  b: (#PID<0.13378.0>) got msg: {:EXIT, #PID<0.13377.0>, {%RuntimeError{message: "Goodbye World!"}, [{NDE.Examples, :loop, 1, [file: 'lib/nde/examples.ex', line: 30]}]}}
  09:49:38.257 [error] Process #PID<0.13377.0> raised an exception
  ** (RuntimeError) Goodbye World!
      (nde) lib/nde/examples.ex:30: NDE.Examples.loop/1


  iex(55)> a = spawn NDE.Examples, :a, [:parent, :kill]
  #PID<0.13423.0>
  a: (#PID<0.13423.0>) Calling Processs.exit(self(), :kill)
  b: (#PID<0.13424.0>) got msg: {:EXIT, #PID<0.13423.0>, :killed}

  iex(56)> a = spawn NDE.Examples, :a, [:child, :kill]
  #PID<0.13426.0>
  b: (#PID<0.13427.0>) Calling Processs.exit(self(), :kill)
  a: (#PID<0.13426.0>) got msg: {:EXIT, #PID<0.13427.0>, :killed}


  iex(66)> a = spawn NDE.Examples, :a, [:parent, :exit]
  #PID<0.13474.0>
  a: (#PID<0.13474.0>) Calling Kernel.exit
  b: (#PID<0.13475.0>) got msg: {:EXIT, #PID<0.13474.0>, :exit_reason}

  iex(67)> a = spawn NDE.Examples, :a, [:child, :exit]
  #PID<0.13477.0>
  b: (#PID<0.13478.0>) Calling Kernel.exit
  a: (#PID<0.13477.0>) got msg: {:EXIT, #PID<0.13478.0>, :exit_reason}


  `catch :exit, _ -> ...` only catches exits in the current process

  iex(12)> a = spawn NDE.Examples, :a_catch_with_trapping_child, [:parent, :exit]
  #PID<0.13645.0>
  a: (#PID<0.13645.0>) Calling Kernel.exit
  Caught exit: exit_reason
  b: (#PID<0.13646.0>) got msg: {:EXIT, #PID<0.13645.0>, :normal}

  iex(13)> a = spawn NDE.Examples, :a_catch_with_trapping_child, [:child, :exit]
  #PID<0.13648.0>
  b: (#PID<0.13649.0>) Calling Kernel.exit


  iex(4)> a = spawn NDE.Examples, :a_catch_without_trapping_child, [:child, :exit]
  #PID<0.13800.0>
  b: (#PID<0.13801.0>) Calling Kernel.exit

  iex(5)> a = spawn NDE.Examples, :a_catch_without_trapping_child, [:child, :exception]
  #PID<0.13803.0>
  b: (#PID<0.13804.0>) Rasing exception
  11:42:54.366 [error] Process #PID<0.13804.0> raised an exception
  ** (RuntimeError) Goodbye World!
      (nde) lib/nde/examples.ex:94: NDE.Examples.loop/1
  
  iex(6)> a = spawn NDE.Examples, :a_catch_without_trapping_child, [:child, :kill]
  #PID<0.13807.0>
  b: (#PID<0.13808.0>) Calling Processs.exit(self(), :kill)

  iex(7)> a = spawn NDE.Examples, :a_catch_without_trapping_child, [:child, :quit]
  #PID<0.13810.0>
  b: (#PID<0.13811.0>) Ending loop
  """
 
  def a(who_dies, how \\ :quit) do
    Process.flag :trap_exit, true
    child = spawn_link &b/0
    case who_dies do
      :parent -> Process.send_after(self(), how, 0)
      :child ->  Process.send_after(child, how, 0)
    end
    loop(:a)
  end

  def b do
    Process.flag :trap_exit, true
    loop(:b)
  end

  def loop(name) do
    receive do
      :quit ->
        IO.puts "#{name}: (#{inspect self()}) Ending loop"
      :kill ->
        IO.puts "#{name}: (#{inspect self()}) Calling Processs.exit(self(), :kill)"
        Process.exit(self(), :kill)
      :exit ->
        IO.puts "#{name}: (#{inspect self()}) Calling Kernel.exit"
        Kernel.exit(:exit_reason)
      :exception ->
        IO.puts "#{name}: (#{inspect self()}) Rasing exception"
        raise "Goodbye World!"
      msg -> 
        IO.puts "#{name}: (#{inspect self()}) got msg: #{inspect msg}"
        loop(name)
    end
  end

  def a_catch_with_trapping_child(who_dies, how \\ :quit) do
    try do
      child = spawn_link &b/0
      case who_dies do
        :parent -> Process.send_after(self(), how, 0)
        :child ->  Process.send_after(child, how, 0)
      end
      loop(:a)
    catch 
      :exit, reason -> IO.puts "Caught exit: #{reason}"
    end
  end

  def a_catch_without_trapping_child(who_dies, how \\ :quit) do
    try do
      child = spawn_link __MODULE__, :loop, [:b]
      case who_dies do
        :parent -> Process.send_after(self(), how, 0)
        :child ->  Process.send_after(child, how, 0)
      end
      loop(:a)
    catch 
      :exit, reason -> IO.puts "Caught exit: #{reason}"
    end
  end

end
