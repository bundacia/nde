defmodule NDE.Counter do
  require Logger

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: NDE.Counter) 
  end

  def inc do
    GenServer.call(__MODULE__, :inc)
  end

  def init(initial_count \\ 0) do
    Process.flag(:trap_exit, true)
    {:ok, %{count: initial_count}}
  end

  def handle_call(:inc, _from, state) do
    new_state = update_in(state[:count], &(&1 + 1))
    {:reply, new_state.count, new_state}
  end

  def handle_info(msg, state) do
    Logger.debug("#{__MODULE__} got message: #{inspect msg}")
    {:noreply, state}
  end

  def terminate(reason, state) do
    Logger.debug("#{__MODULE__} termonated with reason: #{inspect reason}")
  end
end
