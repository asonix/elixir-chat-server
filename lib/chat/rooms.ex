defmodule Chat.Rooms do
  use GenServer

  alias Chat.Room

  defstruct count:     0,
            rooms_map: %{},
            ids_map:   %{}

  defmodule RoomInfo do
    defstruct [:id, :name, :description, :owners, :pid]
  end

  ## Client API

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def create(rooms, name) do
    with {:ok, room_info} <- GenServer.call(rooms, {:create, name}),
      do: Room.info(room_info.pid, room_info)
  end

  def get(rooms, room_info) do
    GenServer.call(rooms, {:get, room_info})
  end

  def join(rooms, user_info, room_info) do
    with {:ok, pid} <- GenServer.call(rooms, {:get, room_info}),
      do: Room.join(pid, user_info)
  end

  def leave(rooms, user_info, room_info) do
    with {:ok, pid} <- GenServer.call(rooms, {:get, room_info}),
      do: Room.leave(pid, user_info)
  end

  def destroy(rooms, room_info) do
    with {:ok, pid} <- GenServer.call(rooms, {:get, room_info}),
         {:ok, :destroyed} <- Room.destroy(pid) do
      GenServer.call(rooms, {:destroy, room_info})
    end
  end

  def list(rooms) do
    with {:ok, room_pids} <- GenServer.call(rooms, {:list}),
      do: {:ok, get_info(room_pids)}
  end

  def list(rooms, room_info) do
    with {:ok, room_pids} <- GenServer.call(rooms, {:list, room_info}),
      do: {:ok, get_info(room_pids)}
  end

  def message(rooms, room_info, message) do
    with {:ok, pid} <- GenServer.call(rooms, {:get, room_info}),
      do: Room.message(pid, message)
  end

  defp get_info(nil), do: nil
  defp get_info(room_pids) do
    room_pids
    |> Enum.map(fn pid ->
      Task.async(fn ->
        try do
          {:ok, info} = Room.info(pid)
          info
        catch
          _ -> nil
        end
      end)
    end)
    |> Enum.map(&Task.await(&1))
    |> Enum.reject(&is_nil(&1))
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %__MODULE__{}}
  end

  def handle_call({:create, room_info}, _from, rooms) do
    case Task.Supervisor.start_child(Chat.RoomSupervisor, fn ->
      Chat.Room.start_link(room_info)
    end) do
      {:ok, pid} ->
        {room_info, rooms} = add_room(rooms, room_info, pid)
        {:reply, {:ok, room_info}, rooms}
      _ ->
        {:reply, {:error, :not_created}, rooms}
    end
  end

  def handle_call({:get, room_info}, _from, rooms) do
    case get_room_pid(rooms, room_info) do
      nil ->
        {:reply, {:error, :doesnt_exist}, rooms}
      pid ->
        {:reply, {:ok, pid}, rooms}
    end
  end

  def handle_call({:destroy, room_info}, _from, rooms) do
    case get_room_pid(rooms, room_info) do
      nil ->
        {:reply, {:ok, :deleted}, rooms}
      _ ->
        {:reply, {:ok, :deleted}, rooms}
    end
  end

  def handle_call({:list}, _from, rooms) do
    pids = Enum.map(rooms.id_map, fn {_id, pid} ->
      pid
    end)

    {:reply, {:ok, pids}, rooms}
  end

  def handle_call({:list, room_info}, _from, rooms) do
    {:reply, {:ok, Map.get(rooms.rooms_map, room_info.name)}, rooms}
  end

  defp add_room(rooms, room_info, pid) do
    room_info = room_info
      |> Map.put(:id, rooms.count+1)
      |> Map.put(:pid, pid)

    rooms = rooms
      |> Map.update(:count, 0, &(&1+1))
      |> update_in([:rooms_map, room_info.name], &into_list(&1, rooms.count+1))
      |> put_in([:ids_map, rooms.count+1], pid)

    {room_info, rooms}
  end

  defp get_room_pid(rooms, %RoomInfo{id: id}) do
    Map.get(rooms.ids_map, id)
  end

  defp into_list(nil, item), do: [item]
  defp into_list(list, item), do: [item | list]

end
