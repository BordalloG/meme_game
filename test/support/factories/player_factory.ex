defmodule MemeGame.PlayerFactory do
  @moduledoc """
    Defines the factory for MemeGame.Game.Player
  """
  defmacro __using__(_opts) do
    quote do
      def player_factory do
        %MemeGame.Game.Player{
          id: "123ABC",
          nick: "Joseph"
        }
      end
    end
  end
end
