defmodule Chat.Connections do
  @type connection :: any
  @type message :: Chat.Message.t

  @callback message(connection, message) :: any
end
