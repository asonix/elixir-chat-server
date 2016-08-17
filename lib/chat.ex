defmodule Chat do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Task.Supervisor, [[strategy: :simple_one_for_one,
                                    name: Chat.RoomSupervisor]])
      # supervisor(Chat.Connections.TCP, [[strategy: :simple_one_for_one]])
    ]

    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
