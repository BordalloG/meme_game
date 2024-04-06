defmodule MemeGameWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :meme_game,
    pubsub_server: MemeGame.PubSub

  @game_topic_prefix "presence:"

  def game_topic(game_id) do
    @game_topic_prefix <> MemeGame.PubSub.game_topic(game_id)
  end

  def track_user(socket_pid, game_id, user_id, user) do
    Phoenix.PubSub.subscribe(MemeGame.PubSub, game_topic(game_id))
    track(socket_pid, game_topic(game_id), user_id, user)
  end

  def list_users(game_id) do
    list(game_topic(game_id))
  end
end
