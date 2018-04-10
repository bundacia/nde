# Near Death Experiences (NDE) in Elixir

The goal of this repo is to better understand how elixir processes behave when they end (die, crash, finish, whatever).

## Exit Signals Between Linked Processes

We'll talk about OTP in a bit, but to start with it's important to understand the basic Elixir (erlang/beam) process all of those OTP Agents and GenServers are built on.

When a process is about to end, it emits an "exit signal" with a `reason` describing why the process exited. The exiting process sends this exit signal to every process to which it is linked.

It's important to remember that linking is a two-way street. So if process `A` uses spawn_link to start process `B` then if process `B` exits it will send an exit signal back to process `A` and if process `A` exits it will send an exit signal to process `B`. In OTP supervision tree terms, this means that OTP processes could send AND recieve exit signals to their supervisors.

I find it helpful to think of these signals more as events than commands. If `B` recieves an exit signal from `A` it should be interpreted as a message informing `B` that `A` has exited, not a command for `B` to exit (even though in most cases that is exactly how `B` will respond). There are excpetions to this (such as when the reason is `:kill` or when a process sends an exit signal to itself) but in general I find the "event" way of thinging about it to be more helpful.

By default, when a process recieves an exit signal it will exit with the same reason from the signal unless the reason is `:normal` in which case the signal will be ignored. We can prove this by spwaning a process with `spawn` and manually sending it an exit signal with `Process.exit(pid, reason)`.

```elixir
iex(1)> pid = spawn fn -> :timer.sleep(:infinity) end
iex(2)> Process.exit(pid, :oops)
iex(3)> Process.alive?(pid)
false

iex(4)> pid = spawn fn -> :timer.sleep(:infinity) end
iex(5)> Process.exit(pid, :normal)
iex(6)> Process.alive?(pid)
true
```

### Trapping Exits

If we want to override the default behavior, we can configure our process to trap exits setting the `trap_exit` flag with `Process.flag :trap_exit, true`. When a process is trapping exits, exit signals it recieves are converted into messages of the form `{:EXIT, from, reason}` and are instered in to the process's message queue.

```elixir
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
```

```
iex(6)> pid = spawn NDE.TrapAndPrint, :trap_and_print, []
#PID<0.139.0>
iex(7)> Process.exit(pid, :normal)
GOT MSG: {:EXIT, #PID<0.117.0>, :normal}
true
iex(8)> Process.exit(pid, :oops)
GOT MSG: {:EXIT, #PID<0.117.0>, :oops}
true
iex(9)> Process.alive?(pid)
true
iex(10)> Process.exit(pid, :kill)
true
iex(11)> Process.alive?(pid)
false
```

Notice the excpetion at the end of the iex session. If a process recieves an exit signal with a reason of `:kill`, it will stop immediately and send an exit signal to it's linked processes with a reason of `:killed`. All other exit signals will just be harmlessly converted into messages that we can respond to or ignore as we like.

Trapping exits is how Supervisors handle exits from their workers.

To recap:

* An exit signal is sent from process A to process B when process A has terminated and A and B are linked.
* The reason will be `:normal` if the exiting process just finished execution normally.
* The reason will be `{exception, stacktrace}` if the exiting process raised an exception.
* The reson will be `:killed` if the exiting process was killed with `Process.exit(pid, :kill)`
* If the receiving process is trapping exits (and the reason is not `:kill`) the signal is converted into a message in the form `{:EXIT, from, reason}`

### Resources
* [Understanding Exit Signals in Erlang/Elixir](https://crypt.codemancers.com/posts/2016-01-24-understanding-exit-signals-in-erlang-slash-elixir/)
* [`&Process.exit/2`](https://hexdocs.pm/elixir/Process.html#exit/2)
* [Elixir Processes Monitoring: :EXIT vs :DOWN](https://stackoverflow.com/questions/42331707/elixir-processes-monitoring-exit-vs-down)

## `Process.monitor`

[`Process.monitor`](https://hexdocs.pm/elixir/Process.html#monitor/1) allows a process to be informed of exits in another process without being linked to it. It works a bit like trapping exits from a linked process, but the monitoring process will not send links to the monitored process when *it* exits. In other words, the messages go only one way.

```elixir
iex(1)> pid = spawn fn -> :timer.sleep(5_000); exit(:death) end
#PID<0.160.0>
iex(2)> Process.monitor(pid)
#Reference<0.366973038.189530118.50442>
iex(3)> receive do
...(3)>   msg -> msg
...(3)> end
{:DOWN, #Reference<0.366973038.189530118.50442>, :process, #PID<0.160.0>,
 :death}
```

## Catching exits with `catch`

When the process emits an exit signal it is possible (though not recommended) to intercept it before it gets sent to any of the linked processes by using a [`try/catch`](https://elixir-lang.org/getting-started/try-catch-and-rescue.html#exits) block.

```elixir
iex(1)> try do
...(1)>   exit(:exit_reason)
...(1)> catch
...(1)>   :exit, reason -> "caught exit #{inspect reason}"
...(1)> end
"caught exit :exit_reason"
```

This does not work for catching exits from linked processes however.

```elixir
iex(1)> try do
...(1)>   spawn_link fn -> exit(:exit_reason) end
...(1)> catch
...(1)>   :exit, reason -> "caught exit #{inspect reason}"
...(1)> end
** (EXIT from #PID<0.117.0>) shell process exited with reason: :exit_reason
```

Notice how the parent process exits with the same reason as the child process, without the exit being caught.

For responding to exits in other processes we should either link to those processes and trap exits or use `Process.monitor`.

## OTP

Now that we understand exit signals a little better, lets see how they're used in OTP processes.

### GenServer

A GenServer process is essentially just an regular elixir/erlang process that consumes messages from its queue in an infinite loop. So most of what we learned so far applies to GenServers as well, but GenServer does provide some extra scafolding.

#### The `&Genserver.terminate/2` callback

`GenServer` provides a [`terminate`](https://hexdocs.pm/elixir/GenServer.html#c:terminate/2) callback.

`terminate/2` is called if a callback (except `init/1`) does one of the following:

* returns a `:stop` tuple
* raises
* calls `Kernel.exit/1`
* returns an invalid value

#### Trapping exits in a GenServer

If the GenServer traps exits and the parent process sends an exit signal `terminate` will also be called. All other exit signals (those not from the parent process) will just show up in the message queue and can be acted on via implementing the `handle_info` callback, which is what gets called with any messages in the queue GenServer doesn't have special handling for (they aren't GenServer "calls" or "casts" or exits from the parent process, etc).

#### Using `terminate` for cleanup code

`terminate` seems like a great place for cleanup code, but there are some gotchas. From the docs:

>If the GenServer receives an exit signal (that is not :normal) from any process when it is not trapping exits it will exit abruptly with the same reason and so not call terminate/2. Note that a process does NOT trap exits by default and an exit signal is sent when a linked process exits or its node is disconnected.

> Therefore it is not guaranteed that terminate/2 is called when a GenServer exits. For such reasons, we usually recommend important clean-up rules to happen in separated processes either by use of monitoring or by links themselves.

### Supervisor

In OTP a [`Supervisor`](https://hexdocs.pm/elixir/Supervisor.html) is a process that has used `spawn_link` to start multiple child process and is trapping exits, so it can restart those child processes ("workers") when they exit (or for a number of other reasons).

From the docs:

> When a supervisor shuts down, it terminates all children in the opposite order they are listed. The termination happens by sending a shutdown exit signal, via Process.exit(child_pid, :shutdown), to the child process and then awaiting for a time interval for the child process to terminate. This interval defaults to 5000 milliseconds. If the child process does not terminate in this interval, the supervisor abruptly terminates the child with reason :brutal_kill. The shutdown time can be configured in the child specification which is fully detailed in the next section.

> If the child process is not trapping exits, it will shutdown immediately when it receives the first exit signal. If the child process is trapping exits, then the terminate callback is invoked, and the child process must terminate in a reasonable time interval before being abruptly terminated by the supervisor.

## Handling OS kill signals

This is described really well in [this blog post](https://jbodah.github.io/blog/2017/05/18/implementing-graceful-exits-elixir/). The big takeaway is that...

> By default the BEAM will exit immediately whenever it receives a SIGTERM

So the `SIGTERM` that convox sends our apps acts like a `kill -9`. 

## Other Links
* [Trapping exit reason in Supervisor (and why not to)](https://elixirforum.com/t/trapping-exit-reason-in-supervisor/7240/5)
