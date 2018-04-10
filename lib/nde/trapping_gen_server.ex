defmodule NDE.TrappingGenServer do
  @moduledoc """
  iex(1)> {:ok, pid} = GenServer.start(NDE.TrappingGenServer, :a)
  {:ok, #PID<0.133.0>}

  iex(2)> Process.exit(pid, :normal)
  a: (#PID<0.133.0>) got msg: {:EXIT, #PID<0.131.0>, :normal}
  true
  iex(3)> Process.alive? pid
  true

  iex(4)> Process.exit(pid, :oops)
  a: (#PID<0.133.0>) got msg: {:EXIT, #PID<0.131.0>, :oops}
  true
  iex(5)> Process.alive? pid
  true

  iex(6)> Process.exit(pid, :shutdown)
  a: (#PID<0.133.0>) got msg: {:EXIT, #PID<0.131.0>, :shutdown}
  true
  iex(7)> Process.alive? pid
  true

  iex(8)> Process.exit(pid, :kill)
  true
  iex(9)> Process.alive? pid
  false

  iex(10)> {:ok, pid} = GenServer.start(NDE.TrappingGenServer, :a)
  {:ok, #PID<0.143.0>}
  iex(11)> send pid, :stop
  a: (#PID<0.143.0>) Stopping loop
  :stop
  a: (#PID<0.143.0>) Terminate called with reason: :stop_reason
  14:50:57.425 [error] GenServer #PID<0.143.0> terminating
  ** (stop) :stop_reason
  Last message: :stop
  State: %{name: :a}
  iex(13)> Process.alive? pid
  false

  iex(14)> {:ok, pid} = GenServer.start(NDE.TrappingGenServer, :a)
  {:ok, #PID<0.148.0>}
  iex(15)> send pid, {:exit, :normal}
  a: (#PID<0.148.0>) Exiting with reason :normal
  {:exit, :normal}
  a: (#PID<0.148.0>) Terminate called with reason: :normal
  iex(16)> Process.alive? pid
  false

  iex(17)> {:ok, pid} = GenServer.start(NDE.TrappingGenServer, :a)
  {:ok, #PID<0.153.0>}
  iex(18)> send pid, :kill
  a: (#PID<0.153.0>) Calling Processs.exit(self(), :kill)
  :kill
  iex(19)> Process.alive? pid
  false

  iex(20)> {:ok, pid} = GenServer.start(NDE.TrappingGenServer, :a)
  {:ok, #PID<0.157.0>}
  iex(21)> send pid, :exit
  a: (#PID<0.157.0>) Calling Kernel.exit
  :exit
  a: (#PID<0.157.0>) Terminate called with reason: :exit_reason
  14:52:11.452 [error] GenServer #PID<0.157.0> terminating
  ** (stop) :exit_reason
      (nde) lib/nde/non_trapping_gen_server.ex:141: NDE.NonTrappingGenServer.handle_info/2
      (stdlib) gen_server.erl:616: :gen_server.try_dispatch/4
      (stdlib) gen_server.erl:686: :gen_server.handle_msg/6
      (stdlib) proc_lib.erl:247: :proc_lib.init_p_do_apply/3
  Last message: :exit
  State: %{name: :a}
  iex(23)> Process.alive? pid
  false

  iex(24)> {:ok, pid} = GenServer.start(NDE.TrappingGenServer, :a)
  {:ok, #PID<0.162.0>}
  iex(25)> send pid, :exception
  a: (#PID<0.162.0>) Rasing exception
  :exception
  a: (#PID<0.162.0>) Terminate called with reason: {%RuntimeError{message: "Goodbye World!"}, [{NDE.NonTrappingGenServer, :handle_info, 2, [file: 'lib/nde/non_trapping_gen_server.ex', line: 144]}, {:gen_server, :try_dispatch, 4, [file: 'gen_server.erl', line: 616]}, {:gen_server, :handle_msg, 6, [file: 'gen_server.erl', line: 686]}, {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 247]}]}
  14:52:26.666 [error] GenServer #PID<0.162.0> terminating
  ** (RuntimeError) Goodbye World!
      (nde) lib/nde/non_trapping_gen_server.ex:144: NDE.NonTrappingGenServer.handle_info/2
      (stdlib) gen_server.erl:616: :gen_server.try_dispatch/4
      (stdlib) gen_server.erl:686: :gen_server.handle_msg/6
      (stdlib) proc_lib.erl:247: :proc_lib.init_p_do_apply/3
  Last message: :exception
  State: %{name: :a}
  iex(27)> Process.alive? pid
  false

  iex(28)> {:ok, pid} = GenServer.start(NDE.TrappingGenServer, :a)
  {:ok, #PID<0.167.0>}
  iex(29)> send pid, :hello
  a: (#PID<0.167.0>) got msg: :hello
  :hello
  iex(30)> Process.alive? pid
  true

  iex(31)> Process.exit(pid, :normal)
  a: (#PID<0.167.0>) got msg: {:EXIT, #PID<0.131.0>, :normal}
  true
  iex(32)> Process.alive? pid
  true

  iex(33)> Process.exit(pid, :shutdown)
  a: (#PID<0.167.0>) got msg: {:EXIT, #PID<0.131.0>, :shutdown}
  true
  iex(34)> Process.alive? pid
  true

  iex(35)> Process.exit(pid, :kill)
  true
  iex(36)> Process.alive? pid
  false
  """
  use GenServer

  def init(args) do
    Process.flag :trap_exit, true
    NDE.NonTrappingGenServer.init(args)
  end

  defdelegate handle_info(msg, state), to: NDE.NonTrappingGenServer
  defdelegate terminate(reason, state), to: NDE.NonTrappingGenServer
end
