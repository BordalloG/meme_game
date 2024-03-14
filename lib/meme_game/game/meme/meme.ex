defmodule MemeGame.Game.Meme do
  @moduledoc """
    Representantion of a Meme
  """
  alias MemeGame.Game.Meme.Field
  alias MemeGame.Game.Player

  @type t :: %__MODULE__{
          id: String.t(),
          img_url: String.t(),
          fields: [Field.t()],
          owner: Player.t(),
          votes: [Vote.t()]
        }

  defstruct [:id, :img_url, :fields, :owner, :votes]
end
