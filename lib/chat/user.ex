defmodule Chat.User do
  use GenServer

  defmodule UserInfo do
    defstruct [:id, :username, :signature, :connection, :connections_module]
  end

  defmodule InvalidUserError do
    defexception [:message]

    def exception(%UserInfo{username: username, id: id}) do
      msg = "Signature for user #{username}##{id} is not valid"

      {:error, %__MODULE__{message: msg}}
    end
  end

  def verify_user(user_info, password) do
    case sign_user(user_info, password) do
      ^user_info -> {:ok, user_info}
      _ -> InvalidUserError.exception(user_info)
    end
  end

  def verify_user!(user_info, password) do
    with {:error, err} <- verify_user(user_info, password), do: raise err
  end

  def message(user_info, message) do
    user_info.connections_module.message(user_info.connection, message)
  end

  ## Public API

  def create(user_info, password) do
    GenServer.call(__MODULE__, {:create, user_info, password})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, 0}
  end

  def handle_call({:create, %{username: username}, password}, _from, count) do
    {:reply, {:ok, sign_user(%UserInfo{id: count, username: username}, password)}, count+1}
  end

  ## Private

  defp sign_user(%UserInfo{id: _id, username: _username} = user_info, _password) do
    %{user_info | signature: 1234}
  end

end
