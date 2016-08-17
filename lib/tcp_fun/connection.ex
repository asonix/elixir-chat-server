defmodule TcpFun.Connection do
  def accept(port) do
    with {:ok, socket} <- :gen_tcp.listen(port,
       [:binary, packet: :line, active: false, reuseaddr: true]),
      do: loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    with {:ok, client} <- :gen_tcp.accept(socket),
      do: Task.Supervisor.start_child(TcpFun.TaskSupervisor, fn -> serve(client) end)

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
