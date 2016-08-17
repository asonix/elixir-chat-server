defmodule Chat.Message do
  @type t :: %{author: String.t,
               body: String.t,
               timestamp: binary}

  defstruct [:author, :body, :timestamp]
end
