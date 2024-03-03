defmodule MemeGame.Game.Meme.Field do
  @moduledoc """
    Represents a text field and it's props in a meme
  """

  alias MemeGame.Game.Meme.Field.Coordinate

  @type t :: %__MODULE__{
          start: Coordinate.t(),
          end: Coordinate.t(),
          text: String.t(),
          color: String.t()
        }

  defstruct [:start, :end, :text, color: "black"]
end
