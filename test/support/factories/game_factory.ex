
defmodule MemeGame.GameFactory do
  @moduledoc """
    Defines the factory for MemeGame.Game
  """
  defmacro __using__(_opts) do
    quote do
      def game_factory do
        %MemeGame.Game{
          id: "123ABC",
          owner: build(:player)
        }
      end
    end
  end
end
