defmodule TcpFun do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Task, [TcpFun.Connection, :accept, [4040]]),
      supervisor(Task.Supervisor, [[strategy: :simple_one_for_one,
                                    name: TcpFun.TaskSupervisor]]),
      supervisor(Task.Supervisor, [[strategy: :simple_one_for_one,
                                    name: TcpFun.RoomSupervisor]])
    ]

    opts = [strategy: :one_for_one, name: TcpFun.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
