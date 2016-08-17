defmodule TcpFun.Rooms do
  use GenServer

  ## Client API

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def create(rooms, room) do
    GenServer.call(rooms, {:create, room})
  end

  def join(rooms, user, room) do
    GenServer.call(rooms, {:join, user, room})
  end

  def leave(rooms, user, room) do
    GenServer.call(rooms, {:leave, user, room})
  end

  def destroy(room) do
    GenServer.call(rooms, {:destroy, room})
  end

  ## Server Callbacks

  def init(:ok) do
    # Structure here is {count, name_map, id_map}
    #
    # name_map %{
    #   name1: [id1, id2, id3],
    #   name2: [id4, id5],
    #   ...
    # }
    #
    # id_map %{
    #   id1: pid1,
    #   id2: pid2,
    #   ...
    # }
    {:ok, {0, %{}, %{}}}
  end

  def handle_call({:create, room}, _from, room_data) do
    case Task.Supervisor.start_child(TcpFun.RoomSupervisor, fn ->
      TcpFun.Room.start_link(room)
    end) do
      {:ok, pid} ->
        {:reply, pid, add_room(room_data, room, pid)}
      _ ->
        {:reply, {:error, :not_created}, room_data}
    end
  end

  def handle_call({:join, user_info, room}, _from, rooms) do
  end

  def handle_call({:destroy, room}, _from, rooms) do
  end

  defp add_room({count, room_map, id_map}, room, pid) do
    id = count + 1

    room_map = Map.get_and_update(room_map, room, fn id_list ->
      if is_nil(id_list), do: [id], else: [id|id_list]
    end)

    id_map = Map.put(id_map, id, pid)

    {id, room_map, id_map}
  end
end
