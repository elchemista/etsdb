defmodule ETSDB.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # maybe considering to start another procces to backup etsdb using 
      # {heir,Pid,HeirData} config on :ets when proccess crash
      worker(ETSDB.DB, []),
      worker(ETSDB.Observer, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ETSDB.Supervisor)
  end
end
