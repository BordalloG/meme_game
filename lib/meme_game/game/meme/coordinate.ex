defmodule MemeGame.Game.Meme.Field.Coordinate do
  @moduledoc """
    Determines the poistion of a point.
  """

  @type t :: %__MODULE__{
          x: integer(),
          y: integer()
        }

  defstruct [:x, :y]
end
