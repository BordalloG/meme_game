defmodule MemeGame.MemeFactory do
  @moduledoc """
    Defines the factory for MemeGame.Game.Meme
  """
  defmacro __using__(_opts) do
    quote do
      def meme_factory do
        %MemeGame.Game.Meme{
          img_url: "https://www.tjtoday.org/wp-content/uploads/2021/01/IMG_7501.jpg",
          fields: build_list(2, :field),
          owner: build(:player)
        }
      end
    end
  end
end
