defmodule MemeGame.ClientServerTest do
  use MemeGame.DataCase
  use ExUnit.Case, async: true

  import MemeGame.Factory

  setup do
    game = build(:game)
    {:ok, pid} = MemeGame.GameServer.Supervisor.start_new_game_server(game.id, game.owner)

    Phoenix.PubSub.subscribe(MemeGame.PubSub, MemeGame.PubSub.game_topic(game))
    {:ok, %{game: game, pid: pid}}
  end

  describe "init" do
    test "starting a game should add owner as a player" do
      game = build(:game)
      {:ok, pid} = MemeGame.GameServer.Supervisor.start_new_game_server(game.id, game.owner)

      game = GenServer.call(pid, :state)

      assert Enum.any?(game.players, fn p -> p == game.owner end)
      assert length(game.players) == 1
    end
  end

  describe "call state" do
    test "should return current game state", %{pid: pid, game: game} do
      assert %MemeGame.Game{} = response = GenServer.call(pid, :state)
      assert response.id == game.id
      assert response.owner == game.owner
    end
  end

  describe "cast join" do
    test "should add a player to the players list", %{pid: pid} do
      player = build(:player)
      GenServer.cast(pid, {:join, player})

      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: payload}
      assert Enum.any?(payload.players, fn p -> p == player end)
    end
  end

  describe "cast next_game_stage" do
    test "should broadcast an error when transition to next stage fails", %{pid: pid} do
      game = GenServer.call(pid, :state)
      GenServer.cast(pid, :next_stage)

      assert game.stage == "wait"
      assert length(game.players) < 2

      assert_receive %Phoenix.Socket.Broadcast{
        event: "error",
        payload: "At least two players are necessary to start the game."
      }
    end

    test "should broadcast the game when transition to next stage succeed", %{pid: pid} do
      player = build(:player, %{nick: "Aleph"})
      GenServer.cast(pid, {:join, player})

      GenServer.cast(pid, :next_stage)

      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _join_response}
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: game}
      assert %MemeGame.Game{} = game
      assert game.stage == "design"
    end
  end

  describe "broadcast_game_update/1" do
    test "should broadcast the game as payload and 'update' as event to the pubsub", %{game: game} do
      Phoenix.PubSub.subscribe(MemeGame.PubSub, MemeGame.PubSub.game_topic(game))

      MemeGame.GameServer.broadcast_game_update(game)

      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: ^game}
    end
  end
end
