defmodule MemeGame.GameServer do
  @moduledoc """
      Module that manage game stages, actions and broadcasts
  """

  use GenServer

  require Logger

  alias MemeGame.Game

  @spec init(map()) :: {atom, Game.t()}
  def init(%{game_id: game_id, owner: owner, locale: locale}) do
    Gettext.put_locale(locale)

    game = %Game{id: game_id, owner: owner, players: [owner]}

    {:ok, game}
  end

  @spec start_link(Game.t()) :: atom
  def start_link(game) do
    GenServer.start_link(__MODULE__, game)
  end

  @spec handle_call(:state, {pid, term()}, Game.t()) :: {:reply, Game.t(), Game.t()}
  def handle_call(:state, _from, game) do
    {:reply, game, game}
  end

  def handle_cast({:join, player}, game) do
    game = %{game | players: [player | game.players]}

    broadcast_game_update(game)
    {:noreply, game}
  end

  @spec handle_cast(:next_stage, Game.t()) :: {:noreply, Game.t()}
  def handle_cast(:next_stage, game) do
    case Game.next_stage(game) do
      {:ok, game} ->
        broadcast_game_update(game)

      {:error, error} ->
        broadcast_game_error(game, error)
    end

    {:noreply, game}
  end

  @spec broadcast_game_update(Game.t()) :: atom
  def broadcast_game_update(game) do
    MemeGame.PubSub.broadcast_game("update", game)
  end

  @spec broadcast_game_error(Game.t(), String.t()) :: :ok
  def broadcast_game_error(game, error) do
    MemeGame.PubSub.broadcast_error(game, error)
  end
end
