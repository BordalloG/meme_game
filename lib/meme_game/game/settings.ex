defmodule MemeGame.Game.Settings do
  @moduledoc """
    Module for managing game settings.
  """
  @type t :: %__MODULE__{
          max_players: integer(),
          rounds: integer()
        }

  defstruct max_players: 4, rounds: 4, score: %{upvote: 10, downvote: -10, midvote: 0}
end
