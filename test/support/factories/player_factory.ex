defmodule MemeGame.PlayerFactory do
  @moduledoc """
    Defines the factory for MemeGame.Game.Player
  """
  defmacro __using__(_opts) do
    quote do
      def player_factory do
        %MemeGame.Game.Player{
          id: Faker.UUID.v4(),
          nick: "Joseph",
          score: 0
        }
      end
    end
  end
end
