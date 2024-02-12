defmodule MemeGame.Game.Player do
  @moduledoc """
      Represents a player present in a Game
  """

  @type t :: %__MODULE__{
          id: String.t(),
          nick: String.t()
        }

  defstruct [:id, :nick]
end
