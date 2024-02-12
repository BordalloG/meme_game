defmodule MemeGame.Game do
  @moduledoc """
      Representation of a Game
  """

  require Logger

  alias MemeGame.Game.Player

  @type t :: %__MODULE__{
          id: String.t(),
          owner: Player.t()
        }

  defstruct [:id, :owner]
end
