defmodule Chat.Room do
  use GenServer

  defstruct users:     [],
            room_info: nil

  ## Client API

  def start_link(room_info) do
    GenServer.start_link(__MODULE__, :ok, [
      name: String.to_atom("#{room_info.id}-" <> room_info.name)
    ])
  end

  def join(room, user_info) do
    GenServer.cast(room, {:join, user_info})

    {:ok, :joined}
  end

  def leave(room, user_info) do
    GenServer.cast(room, {:leave, user_info})

    {:ok, :left}
  end

  def destroy(room) do
    GenServer.call(room, {:destroy})
  end

  def info(room) do
    GenServer.call(room, {:info})
  end

  def info(room, room_info) do
    GenServer.cast(room, {:info, room_info})

    {:ok, :set}
  end

  def message(room, message) do
    GenServer.cast(room, {:message, message})

    {:ok, :sent}
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %__MODULE__{}}
  end

  def handle_call({:destroy}, _from, room) do
    {:stop, :destroyed, {:ok, :destroyed}, room}
  end

  def handle_call({:info}, _from, room) do
    {:reply, {:ok, room.room_info}, room}
  end

  def handle_cast({:info, room_info}, _from, room) do
    room_info = %{ room_info |
      name: room_info.name,
      description: room_info.description }

    {:noreply, room_info}
  end

  def handle_cast({:message, message}, _from, room) do
    message_users(room, message)
    {:noreply, room}
  end

  def handle_cast({:join, user_info}, _from, room) do
    {:noreply, add_user(room, user_info)}
  end

  def handle_cast({:leave, user_info}, _from, room) do
    {:noreply, remove_user(room, user_info)}
  end

  defp message_users(room, message) do
    room.users
    |> Enum.map(fn user_info ->
      Task.async(fn ->
        try do
          Chat.User.message(user_info, message)
        catch
          _ -> nil
        end
      end)
    end)
    |> Enum.each(&Task.await(&1))
  end

  defp add_user(room, user_info) do
    room
    |> remove_user(user_info) # You only join once
    |> Map.update(:users, [user_info], fn users ->
      [user_info | users]
    end)
  end

  defp remove_user(room, user_info) do
    Map.update(room, :users, [], fn users ->
      Enum.reject(users, fn user ->
        user.id == user_info.id
      end)
    end)
  end
end
