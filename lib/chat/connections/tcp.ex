defmodule Chat.Connections.TCP do
  @behaviour Chat.Connections

  def message(socket, message) do
    message
    |> format
    |> write_line(socket)
  end

  defp format(message) do
    "MESSAGE\r\n#{message.author}\r\n#{message.body}\r\n#{message.timestamp}\r\nEND"
  end

  ## Setup

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Task, [Chat.Connections.TCP, :accept, [4040]]),
      supervisor(Task.Supervisor, [[strategy: :simple_one_for_one,
                                    name: Chat.Connections.TCP.TaskSupervisor]]),
    ]

    opts = [strategy: :one_for_one, name: Chat.Connections.TCP.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def accept(port) do
    with {:ok, socket} <- :gen_tcp.listen(port,
       [:binary, packet: :line, active: false, reuseaddr: true]),
      do: loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    with {:ok, client} <- :gen_tcp.accept(socket) do
      Task.Supervisor.start_child(Chat.Connections.TCP.TaskSupervisor, fn ->
        serve(client)
      end)
    end

    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line
    |> write_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} -> data
      _ -> nil
    end
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end

end
