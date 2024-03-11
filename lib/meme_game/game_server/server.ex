defmodule MemeGame.GameServer do
  @moduledoc """
      Module that manage game stages, actions and broadcasts
  """

  use GenServer

  import MemeGameWeb.Gettext

  require Logger

  alias MemeGame.Game
  alias MemeGame.Game.{Meme, Player}

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
  def handle_call(:state, _from, %Game{} = game) do
    {:reply, game, game}
  end

  @spec handle_cast({:join, Player.t()}, Game.t()) :: {:noreply, Game.t()}
  def handle_cast({:join, player}, %Game{} = game) do
    if length(game.players) >= game.settings.max_players do
      {:noreply, broadcast_game_error(game, dgettext("errors", "Game is full"))}
    else
      game = %{game | players: [player | game.players]}

      {:noreply, broadcast_game_update(game)}
    end
  end

  @spec handle_cast({:leave, Player.t()}, Game.t()) :: {:noreply, Game.t()}
  def handle_cast({:leave, player}, %Game{} = game) do
    game = %{game | players: Enum.filter(game.players, fn p -> p != player end)}

    {:noreply, broadcast_game_update(game)}
  end

  @spec handle_cast(:next_stage, Game.t()) :: {:noreply, Game.t()}
  def handle_cast(:next_stage, %Game{} = game) do
    game =
      case Game.next_stage(game) do
        {:ok, game} ->
          broadcast_game_update(game)

        {:error, error} ->
          broadcast_game_error(game, error)
      end

    {:noreply, game}
  end

  @spec handle_cast({:submit_meme, Meme.t()}, Game.t()) :: {:noreply, Game.t()}
  def handle_cast({:submit_meme, %Meme{} = meme}, %Game{stage: "design"} = game) do
    current_round = Game.current_round(game)

    if Enum.find(current_round.memes, fn m -> m.owner == meme.owner end) do
      {:noreply,
       broadcast_game_error(game, dgettext("errors", "You can send only one meme per round"))}
    else
      current_round = %{current_round | memes: current_round.memes ++ [meme]}

      # adding updated round to struct
      game = %{
        game
        | rounds:
            Enum.map(game.rounds, fn round ->
              if round.number == game.current_round do
                current_round
              else
                round
              end
            end)
      }

      if length(current_round.memes) == length(game.players) do
        {:ok, game} = Game.next_stage(game)
        {:noreply, broadcast_game_update(game)}
      else
        {:noreply, broadcast_game_update(game)}
      end
    end
  end

  def handle_cast({:submit_meme, _meme}, %Game{} = game) do
    {:noreply,
     broadcast_game_error(
       game,
       dgettext("errors", "Memes can only be submitted during the design stage.")
     )}
  end

  @spec broadcast_game_update(Game.t()) :: Game.t()
  def broadcast_game_update(%Game{} = game) do
    MemeGame.PubSub.broadcast_game("update", game)
    game
  end

  @spec broadcast_game_error(Game.t(), String.t()) :: Game.t()
  def broadcast_game_error(%Game{} = game, error) do
    MemeGame.PubSub.broadcast_error(game, error)
    game
  end
end
