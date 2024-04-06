defmodule MemeGame.GameServer do
  @moduledoc """
      Module that manage game stages, actions and broadcasts
  """

  use GenServer

  import MemeGameWeb.Gettext

  require Logger

  alias MemeGame.Game
  alias MemeGame.Game.{Meme, Player}
  alias MemeGame.Game.Meme.Vote
  alias MemeGame.GameServer.ServerName

  @spec init(map()) :: {atom, Game.t()}
  def init(%{game_id: game_id, owner: owner, locale: locale}) do
    Gettext.put_locale(locale)

    Phoenix.PubSub.subscribe(MemeGame.PubSub, MemeGameWeb.Presence.game_topic(game_id))

    game = %Game{id: game_id, owner: owner, players: [owner]}

    {:ok, game}
  end

  @spec start_link(Game.t()) :: atom
  def start_link(game) do
    GenServer.start_link(__MODULE__, game)
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "presence_diff",
          payload: %{joins: _joins, leaves: leaves}
        },
        %Game{} = game
      ) do
    # TODO: If leaves, set a timer to check if reconnect else leave depending on game stage
    players_leaving =
      Enum.map(
        leaves,
        fn {_id, %{metas: metas}} ->
          struct(Player, Map.from_struct(hd(metas)))
        end
      )

    leave(players_leaving, game)
  end

  @spec handle_call(:state, {pid, term()}, Game.t()) :: {:reply, Game.t(), Game.t()}
  def handle_call(:state, _from, %Game{} = game) do
    {:reply, game, game}
  end

  @spec handle_call({:join, Player.t()}, {pid, term()}, Game.t()) ::
          {:reply, {:ok, Game.t()}, Game.t()} | {:reply, {:error, :game_full}, Game.t()}
  def handle_call({:join, player}, _from, %Game{} = game) do
    join(player, game)
  end

  @spec handle_cast({:leave, Player.t()}, Game.t()) :: {:noreply, Game.t()}
  def handle_cast({:leave, player}, %Game{} = game) do
    leave([player], game)
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

      game = Game.update_current_round(game, current_round)

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

  def handle_cast({:vote, player, %{owner: player} = _meme, _value}, game) do
    {:noreply,
     broadcast_game_error(
       game,
       dgettext("errors", "You cannot vote your own meme")
     )}
  end

  def handle_cast({:vote, player, meme, value}, %Game{stage: "vote"} = game) do
    vote = %Vote{player: player, value: value}
    current_round = Game.current_round(game)

    meme = Enum.find(current_round.memes, fn m -> m.id == meme.id end)
    updated_meme = %{meme | votes: [vote | meme.votes]}

    current_round = %{
      current_round
      | memes:
          Enum.map(current_round.memes, fn m ->
            if m == meme do
              updated_meme
            else
              m
            end
          end)
    }

    game = Game.update_current_round(game, current_round)
    {:noreply, game}
  end

  def handle_cast({:vote, _, _, _}, game) do
    {:noreply,
     broadcast_game_error(
       game,
       dgettext("errors", "Votes are only allowed during the vote stage")
     )}
  end

  def terminate(reason, game) do
    Logger.info("Game with id #{game.id} exit with reason #{inspect(reason)}")
    ServerName.remove_game_pid(game.id)
  end

  @spec broadcast_game_end(Game.t(), String.t()) :: :ok
  def broadcast_game_end(game, message) do
    MemeGame.PubSub.broadcast_end(game, message)
    :ok
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

  @spec leave([Player.t()], Game.t()) ::
          {:noreply, Game.t()} | {:stop, {:shutdown, :no_players_left}, Game.t()}
  defp leave(players, game) do
    game = %{game | players: game.players -- players}

    if Enum.empty?(game.players) do
      broadcast_game_end(game, "no players left")
      {:stop, {:shutdown, :no_players_left}, game}
    else
      game =
        if Enum.any?(game.players, fn player -> player == game.owner end) do
          game
        else
          %{game | owner: Enum.random(game.players)}
        end

      {:noreply, broadcast_game_update(game)}
    end
  end

  @spec join(map(), Game.t()) ::
          {:reply, {:ok, Game.t()}, Game.t()} | {:reply, {:error, String.t()}, Game.t()}
  defp join(player, %Game{} = game) do
    if Game.player_in_game?(player, game) do
      {:reply, {:ok, game}, game}
    else
      case Game.can_join?(game, player) do
        {:ok, game} ->
          game = %{game | players: game.players ++ [player]}
          {:reply, {:ok, game}, broadcast_game_update(game)}

        {:error, reasons} ->
          reason = Enum.join(reasons, " ")
          broadcast_game_error(game, reason)
          {:reply, {:error, reason}, game}
      end
    end
  end
end
