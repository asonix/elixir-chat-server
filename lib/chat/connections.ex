defmodule Chat.Connections do
  @type connection :: any
  @type message :: Chat.Message.t

  @callback message(connection, message) :: any

  defmodule API do

    defmodule MissingFieldsError do
      defexception [:message]
    end

    def new_user(%{username: nil}, _password), do: user_info_error(:new)
    def new_user(%{connection: nil}, _password), do: user_info_error(:new)
    def new_user(%{connections_module: nil}, _password), do: user_info_error(:new)
    def new_user(_user_info, nil), do: password_error
    def new_user(user_info, password) do
      Chat.User.create(user_info, password)
    end

    def returning_user(%{id: nil}=user_info, password), do: new_user(user_info, password)
    def returning_user(%{username: nil}, _password), do: user_info_error(:returning)
    def returning_user(%{connection: nil}, _password), do: user_info_error(:returning)
    def returning_user(%{connections_module: nil}, _password), do: user_info_error(:returning)
    def returning_user(_user_info, nil), do: password_error
    def returning_user(user_info, password) do
      Chat.User.verify_user(user_info, password)
    end

    def join_room(%{pid: nil, id: nil}, _user_info), do: room_info_error
    def join_room(%{pid: nil, name: nil}, _user_info), do: room_info_error
    def join_room(_room_info, %{id: nil}), do: user_info_error(:join)
    def join_room(_room_info, %{username: nil}), do: user_info_error(:join)
    def join_room(_room_info, %{connection: nil}), do: user_info_error(:join)
    def join_room(_room_info, %{connections_module: nil}), do: user_info_error(:join)
    def join_room(%{pid: nil}=room_info, user_info) do
      Rooms.join(Chat.Rooms, user_info, room_info)
    def join_room(%{pid: pid}, user_info) do
      Room.join(pid, user_info)
    end

    def message_room(%{pid: nil, id: nil}, _message), do: room_info_error
    def message_room(%{pid: nil, name: nil}, _message), do: room_info_error
    def message_room(_room_info, %{author: nil}), do: message_error
    def message_room(_room_info, %{body: nil}), do: message_error
    def message_room(_room_info, %{timestamp: nil}), do: message_error
    def message_room(%{pid: nil}=room_info, message) do
      Rooms.message(Chat.Rooms, room_info, message)
    end
    def message_room(%{pid: pid}, message) do
      Room.message(pid, message)
    end

    def leave_room(%{pid: nil, id: nil}, _user_info), do: room_info_error
    def leave_room(%{pid: nil, name: nil}, _user_info), do: room_info_error
    def leave_room(_room_info, %{id: nil}), do: user_info_error(:leave)
    def leave_room(%{pid: nil}=room_info, user_info) do
      Rooms.leave(Chat.Rooms, user_info, room_info)
    def leave_room(%{pid: pid}, user_info) do
      Room.leave(pid, user_info)
    end

    defp user_info_error(:new) do
      {:error, %MissingFieldsError{
        message: "UserInfo requires :username, :connection, :connections_module"
      }}
    end

    defp user_info_error(:join) do
      {:error, %MissingFieldsError{
        message: "UserInfo requires :username, :id, :connection, :connections_module"
      }}
    end

    defp user_info_error(:returning) do
      {:error, %MissingFieldsError{
        message: "UserInfo requires :username, :id, :connection, connections_module"
      }}
    end

    defp user_info_error(:leave) do
      {:error, %MissingFieldsError{
        message: "UserInfo requires :id"
      }}
    end

    defp password_error do
      {:error, %MissingFieldsError{
        message: "Password must be present"
      }}
    end

    defp room_info_error do
      {:error, %MissingFieldsError{
        message: "RoomInfo requires :id and :name OR :pid"
      }}
    end

    defp message_error do
      {:error, %MissingFieldsError{
        message: "Message requires :author, :body, and :timestamp"
      }}
    end
  end
end
