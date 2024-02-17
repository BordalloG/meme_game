defmodule MemeGame.GameServer do
  @moduledoc """
      Module that manage game stages, actions and broadcasts
  """

  import MemeGameWeb.Gettext

  use GenServer

  require Logger

  alias MemeGame.Game

  @spec init(map()) :: {atom, Game.t()}
  def init(%{room_id: room_id, owner: owner, locale: locale}) do
    Logger.info("Starting new game server - room_id: #{room_id}")
    Gettext.put_locale(locale)
    Phoenix.PubSub.subscribe(MemeGame.PubSub, room_id)
    game = %Game{id: room_id, owner: owner}

    {:ok, game}
  end

  @spec start_link(MemeGame.Game.t()) :: atom
  def start_link(game) do
    GenServer.start_link(__MODULE__, game)
  end

  @spec broadcast_game_update(Game.t()) :: atom
  def broadcast_game_update(game) do
    MemeGame.PubSub.broadcast_game("update", game)
  end
end
