defmodule MemeGame.Game.Round do
  @moduledoc """
    Definition of a round
  """
  alias MemeGame.Game.Meme

  @type t :: %__MODULE__{
          number: integer(),
          memes: [Meme.t()]
        }

  defstruct number: 1, memes: []
end
