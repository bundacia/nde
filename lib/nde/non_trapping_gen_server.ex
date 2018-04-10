defmodule NDE.NonTrappingGenServer do
  @moduledoc """
  iex(9)> {:ok, pid} = GenServer.start(NDE.NonTrappingGenServer, :a)
  {:ok, #PID<0.137.0>}

  iex(10)> Process.exit(pid, :normal)
  true
  iex(11)> Process.alive? pid
  true

  iex(12)> Process.exit(pid, :oops)
  true
  iex(13)> Process.alive? pid
  false

  iex(14)> {:ok, pid} = GenServer.start(NDE.NonTrappingGenServer, :a)
  {:ok, #PID<0.143.0>}

  iex(15)> send pid, :stop
  a: (#PID<0.143.0>) Stopping loop
  :stop
  a: (#PID<0.143.0>) Terminate called with reason: :stop_reason
  14:40:20.280 [error] GenServer #PID<0.143.0> terminating
  ** (stop) :stop_reason
  Last message: :stop
  State: %{name: :a}
  

  iex(17)> send pid, {:exit, :normal}
  {:exit, :normal}


  iex(18)> Process.alive? pid
  false


  iex(19)> {:ok, pid} = GenServer.start(NDE.NonTrappingGenServer, :a)
  {:ok, #PID<0.150.0>}


  iex(20)> send pid, :kill
  a: (#PID<0.150.0>) Calling Processs.exit(self(), :kill)
  :kill


  iex(21)> Process.alive? pid
  false


  iex(22)> {:ok, pid} = GenServer.start(NDE.NonTrappingGenServer, :a)
  {:ok, #PID<0.154.0>}


  iex(23)> send pid, :exit
  a: (#PID<0.154.0>) Calling Kernel.exit
  :exit
  a: (#PID<0.154.0>) Terminate called with reason: :exit_reason
  14:41:21.970 [error] GenServer #PID<0.154.0> terminating
  ** (stop) :exit_reason
      (nde) lib/nde/non_trapping_gen_server.ex:23: NDE.NonTrappingGenServer.handle_info/2
      (stdlib) gen_server.erl:616: :gen_server.try_dispatch/4
      (stdlib) gen_server.erl:686: :gen_server.handle_msg/6
      (stdlib) proc_lib.erl:247: :proc_lib.init_p_do_apply/3
  Last message: :exit
  State: %{name: :a}
  
  iex(25)> Process.alive? pid
  false

  iex(26)> {:ok, pid} = GenServer.start(NDE.NonTrappingGenServer, :a)
  {:ok, #PID<0.159.0>}

  iex(27)> send pid, :exception
  a: (#PID<0.159.0>) Rasing exception
  :exception
  a: (#PID<0.159.0>) Terminate called with reason: {%RuntimeError{message: "Goodbye World!"}, [{NDE.NonTrappingGenServer, :handle_info, 2, [file: 'lib/nde/non_trapping_gen_server.ex', line: 26]}, {:gen_server, :try_dispatch, 4, [file: 'gen_server.erl', line: 616]}, {:gen_server, :handle_msg, 6, [file: 'gen_server.erl', line: 686]}, {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 247]}]}
  14:41:35.250 [error] GenServer #PID<0.159.0> terminating
  ** (RuntimeError) Goodbye World!
      (nde) lib/nde/non_trapping_gen_server.ex:26: NDE.NonTrappingGenServer.handle_info/2
      (stdlib) gen_server.erl:616: :gen_server.try_dispatch/4
      (stdlib) gen_server.erl:686: :gen_server.handle_msg/6
      (stdlib) proc_lib.erl:247: :proc_lib.init_p_do_apply/3
  Last message: :exception
  State: %{name: :a}
  
  iex(29)> Process.alive? pid
  false

  iex(30)> {:ok, pid} = GenServer.start(NDE.NonTrappingGenServer, :a)
  {:ok, #PID<0.164.0>}

  iex(31)> send pid, :hello
  a: (#PID<0.164.0>) got msg: :hello
  :hello

  iex(32)> Process.alive? pid
  true

  iex(33)> Process.exit(pid, :normal)
  true

  iex(34)> Process.alive? pid
  true

  iex(35)> Process.exit(pid, :shutdown)
  true

  iex(36)> Process.alive? pid
  false

  iex(37)> {:ok, pid} = GenServer.start(NDE.NonTrappingGenServer, :a)
  {:ok, #PID<0.172.0>}

  iex(38)> Process.exit(pid, :kill)
  true

  iex(39)> Process.alive? pid
  false
  """
  use GenServer

  def init(name) do
    {:ok, %{name: name}}
  end

  def handle_info(msg, state) do
    case msg do
      :stop ->
        log(state, "Stopping loop")
        {:stop, :stop_reason, state}
      {:exit, reason} ->
        log(state, "Exiting with reason #{inspect reason}")
        Process.exit(self(), reason)
        {:noreply, state}
      :kill ->
        log(state, "Calling Processs.exit(self(), :kill)")
        Process.exit(self(), :kill)
        {:noreply, state}
      :exit ->
        log(state, "Calling Kernel.exit")
        Kernel.exit(:exit_reason)
      :exception ->
        log(state, "Rasing exception")
        raise "Goodbye World!"
      msg -> 
        log(state, "got msg: #{inspect msg}")
        {:noreply, state}
    end
  end
  
  def terminate(reason, state) do
    log(state, "Terminate called with reason: #{inspect reason}")
  end

  defp log(%{name: name}, msg) do
    IO.puts "#{name}: (#{inspect self()}) #{msg}"
  end
end
