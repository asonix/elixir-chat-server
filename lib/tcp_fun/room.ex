defmodule TcpFun.Room do
  use GenServer

  ## Client API

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, [name: name])
  end

  def join(user, room) do
  end

  def destroy(room) do
  end

  ## Server Callbacks

  def init(:ok, opts) do
    {:ok, %{users: [], messages: []}}
  end

  def handle_cast({:join, user}, _from, room) do
  end

  def handle_cast({:destroy}, _from, room) do
  end
end
