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
          votes: [Vote.t()],
          score: integer()
        }

  defstruct [:id, :img_url, :fields, :owner, :votes, score: 0]

  @spec update_score(Meme.t(), integer()) :: Meme.t()
  def update_score(meme, new_score) do
    %{meme | score: new_score}
  end
end
