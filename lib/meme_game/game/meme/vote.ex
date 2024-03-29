defmodule MemeGame.Game.Meme.Vote do
  @moduledoc """
    Represents a Meme vote, it can be up, down or mid
  """
  alias MemeGame.Game.Player

  @type value :: :upvote | :downvote | :midvote

  @type t :: %__MODULE__{
          player: Player.t(),
          value: value()
        }

  defstruct [:player, :value]
end
