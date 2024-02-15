defmodule MemeGame.SettingsFactory do
  @moduledoc """
    Defines the factory for MemeGame.Game.Player
  """
  defmacro __using__(_opts) do
    quote do
      def settings_factory do
        %MemeGame.Game.Settings{
          max_players: 4
        }
      end
    end
  end
end