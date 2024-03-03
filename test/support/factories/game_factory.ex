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
          players: build_list(2, :player),
          settings: build(:settings),
          current_round: 1,
          rounds: []
        }
      end
    end
  end
end
