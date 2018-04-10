# NDE

* https://jbodah.github.io/blog/2017/05/18/implementing-graceful-exits-elixir/

> By default the BEAM will exit immediately whenever it receives a SIGTERM

* https://crypt.codemancers.com/posts/2016-01-24-understanding-exit-signals-in-erlang-slash-elixir/
* https://elixirforum.com/t/trapping-exit-reason-in-supervisor/7240/10
* https://stackoverflow.com/questions/42331707/elixir-processes-monitoring-exit-vs-down

an exit signal is sent from process A to process B when process A has terminated, A and B are linked. If process B is trapping exits the signal is converted into a message in the form `{:EXIT, from, reason}`
reason will be `:normal` if the process just finished execution normally.
reason will be `{exception, stacktrace}` if the process raised an exception.
reson will be `:killed` if the process was killed with `Process.exit(pid, :kill)`


:DOWN is a message that process A sens to process B when B has called Process.monitor(A) to monitor A and A has terminated

Erlang GenServer calls the terminate callback when an EXIT message is recieved. The Exit messate will not make it to handle info(?)

b GenServer.terminate
https://hexdocs.pm/elixir/GenServer.html#c:terminate/2
> If part of a supervision tree, a GenServer’s Supervisor will send an exit signal when shutting it down.
