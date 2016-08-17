defmodule TcpFun.User do
  use GenServer

  defmodule UserInfo do
    defstruct [:id, :username, :signature]
  end

  defmodule InvalidUserError do
    defexception [:message]

    def exception(%UserInfo{username: username, id: id}) do
      msg = "Signature for user #{username}##{id} is not valid"

      {:error, %__MODULE__{message: msg}}
    end
  end

  def verify_user(user_info) do
    case sign_user(user_info) do
      ^user_info -> {:ok, user_info}
      _ -> InvalidUserError.exception(user_info)
    end
  end

  def verify_user!(user_info) do
    with {:error, err} <- verify_user(user_info), do: raise err
  end

  ## Public API

  def create(username) do
    GenServer.call(__MODULE__, {:create, username})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, count}
  end

  def handle_call({:create, username}, _from, count) do
    {:reply, sign_user(%UserInfo{id: count, username: username}), count+1}
  end

  ## Private

  defp sign_user(%UserInfo{id: _id, username: _username} = user_info) do
    %{user_info | signature: 1234}
  end

end
