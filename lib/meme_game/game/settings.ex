defmodule MemeGame.Game.Settings do
  @moduledoc """
    Module for managing game settings.
  """
  @type t :: %__MODULE__{
          max_players: integer()
        }

  defstruct max_players: 4
end
