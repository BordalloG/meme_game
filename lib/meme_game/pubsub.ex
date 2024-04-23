defmodule MemeGame.PubSub do
  @moduledoc """
      Simplify and standardize Pub Sub activities
  """

  alias MemeGame.Game

  @spec chat_topic(String.t()) :: String.t()
  def chat_topic(game_id), do: "chat:#{game_id}"

  @spec game_topic(String.t()) :: String.t()
  def game_topic(game_id) when is_binary(game_id), do: "game:#{game_id}"

  @spec game_topic(Game.t()) :: String.t()
  def game_topic(%Game{} = game), do: "game:#{game.id}"

  @spec broadcast_game(String.t(), Game.t()) :: atom
  def broadcast_game(event, %Game{} = game) do
    Phoenix.PubSub.broadcast(MemeGame.PubSub, game_topic(game), %Phoenix.Socket.Broadcast{
      topic: game_topic(game),
      event: event,
      payload: game
    })
  end

  @spec broadcast_error(Game.t(), String.t()) :: atom
  def broadcast_error(%Game{} = game, error) do
    Phoenix.PubSub.broadcast(MemeGame.PubSub, game_topic(game), %Phoenix.Socket.Broadcast{
      topic: game_topic(game),
      event: "error",
      payload: error
    })
  end

  @spec broadcast_end(Game.t(), String.t()) :: atom
  def broadcast_end(game, message) do
    Phoenix.PubSub.broadcast(MemeGame.PubSub, game_topic(game), %Phoenix.Socket.Broadcast{
      topic: game_topic(game),
      event: "end",
      payload: message
    })
  end

  @spec broadcast_chat_message(String.t(), map()) :: atom
  def broadcast_chat_message(game_id, %{sender: _sender, text: _text} = message) do
    Phoenix.PubSub.broadcast(MemeGame.PubSub, chat_topic(game_id), %Phoenix.Socket.Broadcast{
      topic: chat_topic(game_id),
      event: "chat_message",
      payload: message
    })
  end
end
