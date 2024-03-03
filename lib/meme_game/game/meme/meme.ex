defmodule MemeGame.Game.Meme do
  @moduledoc """
    Representantion of a Meme
  """
  alias MemeGame.Game.Meme.Field
  alias MemeGame.Game.Player

  @type t :: %__MODULE__{
          img_url: String.t(),
          fields: [Field.t()],
          owner: Player.t()
        }

  defstruct [:img_url, :fields, :owner]
end
