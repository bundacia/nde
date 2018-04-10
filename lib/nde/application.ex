defmodule NDE.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a counter by calling: NDE.Counter.start_link(0)
      {NDE.Counter, 0},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NDE.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
