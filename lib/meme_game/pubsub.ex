defmodule MemeGame.PubSub do
  @moduledoc """
      Simplify and standardize Pub Sub activities
  """

  alias MemeGame.Game

  def game_topic(game) do
    "game:#{game.id}"
  end

  @spec broadcast_game(String.t(), Game.t()) :: atom
  def broadcast_game(event, game) do
    topic = "game:#{game.id}"

    Phoenix.PubSub.broadcast(MemeGame.PubSub, topic, %Phoenix.Socket.Broadcast{
      topic: game_topic(game),
      event: event,
      payload: game
    })
  end
end
