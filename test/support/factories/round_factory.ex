defmodule MemeGame.RoundFactory do
  @moduledoc """
    Defines the factory for MemeGame.Game.Round
  """
  defmacro __using__(_opts) do
    quote do
      def round_factory do
        %MemeGame.Game.Round{
          number: 1,
          memes: []
        }
      end
    end
  end
end
