defmodule MemeGame.GameFactory do
  @moduledoc """
    Defines the factory for MemeGame.Game
  """
  defmacro __using__(_opts) do
    quote do
      def game_factory do
        owner = build(:player)

        %MemeGame.Game{
          id: Faker.UUID.v4(),
          owner: owner,
          stage: "wait",
          players: build_list(2, :player) ++ [owner],
          settings: build(:settings),
          current_round: 1,
          rounds: []
        }
      end
    end
  end
end
