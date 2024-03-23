defmodule MemeGame.Game.Player do
  @moduledoc """
      Represents a player present in a Game
  """

  @type t :: %__MODULE__{
          id: String.t(),
          nick: String.t(),
          score: integer()
        }

  defstruct [:id, :nick, score: 0]
end
