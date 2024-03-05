defmodule MemeGame.PubSub do
  @moduledoc """
      Simplify and standardize Pub Sub activities
  """

  alias MemeGame.Game

  @spec game_topic(String.t()) :: String.t()
  def game_topic(game_id) when is_binary(game_id), do: "game:#{game_id}"

  @spec game_topic(Game.t()) :: String.t()
  def game_topic(%Game{} = game), do: "game:#{game.id}"

  @spec broadcast_game(String.t(), Game.t()) :: atom
  def broadcast_game(event, %Game{} = game) do
    topic = "game:#{game.id}"

    Phoenix.PubSub.broadcast(MemeGame.PubSub, topic, %Phoenix.Socket.Broadcast{
      topic: game_topic(game),
      event: event,
      payload: game
    })
  end

  @spec broadcast_error(Game.t(), String.t()) :: atom
  def broadcast_error(%Game{} = game, error) do
    topic = "game:#{game.id}"

    Phoenix.PubSub.broadcast(MemeGame.PubSub, topic, %Phoenix.Socket.Broadcast{
      topic: game_topic(game),
      event: "error",
      payload: error
    })
  end
end
