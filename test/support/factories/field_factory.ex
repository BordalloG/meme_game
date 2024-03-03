defmodule MemeGame.FieldFactory do
  @moduledoc """
    Defines the factory for MemeGame.Game.Meme.Field
  """
  defmacro __using__(_opts) do
    quote do
      def field_factory do
        %MemeGame.Game.Meme.Field{
          start: build(:coordinate),
          end: build(:coordinate, %{x: 200, y: 200}),
          text: "Dad joke here.",
          color: "black"
        }
      end
    end
  end
end
