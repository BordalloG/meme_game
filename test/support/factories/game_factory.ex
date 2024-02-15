defmodule MemeGame.GameFactory do
  @moduledoc """
    Defines the factory for MemeGame.Game
  """
  defmacro __using__(_opts) do
    quote do
      def game_factory do
        %MemeGame.Game{
          id: "123ABC",
          owner: build(:player),
          stage: "wait",
          players: build_list(4, :player)
        }
      end
    end
  end
end
