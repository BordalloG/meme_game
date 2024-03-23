defmodule MemeGame.VoteFactory do
  @moduledoc """
    Defines the factory for MemeGame.Game.Meme.Vote
  """
  defmacro __using__(_opts) do
    quote do
      def vote_factory do
        %MemeGame.Game.Meme.Vote{
          player: build(:player),
          value: Enum.take_random([:upvote, :downvote, :midvote], 1) |> hd
        }
      end
    end
  end
end
