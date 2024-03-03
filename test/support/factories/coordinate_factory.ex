defmodule MemeGame.CoordinateFactory do
  @moduledoc """
    Defines the factory for MemeGame.Game.Meme.Field.Coordinate
  """
  defmacro __using__(_opts) do
    quote do
      def coordinate_factory do
        %MemeGame.Game.Meme.Field.Coordinate{
          x: 100,
          y: 100
        }
      end
    end
  end
end
