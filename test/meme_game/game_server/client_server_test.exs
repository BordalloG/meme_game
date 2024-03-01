defmodule MemeGame.ClientServerTest do
  use MemeGame.DataCase
  use ExUnit.Case, async: true

  alias MemeGame.GameServer.Client

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
      {:ok, _pid} = MemeGame.GameServer.Supervisor.start_new_game_server(game.id, game.owner)

      game = Client.state(game.id)

      assert Enum.any?(game.players, fn p -> p == game.owner end)
      assert length(game.players) == 1
    end
  end

  describe "call state" do
    test "should return current game state", %{game: game} do
      assert %MemeGame.Game{} = response = Client.state(game.id)
      assert response.id == game.id
      assert response.owner == game.owner
    end
  end

  describe "cast join" do
    test "should add a player to the players list", %{game: game} do
      player = build(:player)

      Client.join(game.id, player)

      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: payload}
      assert Enum.any?(payload.players, fn p -> p == player end)
    end
  end

  describe "cast next_game_stage" do
    test "should broadcast an error when transition to next stage fails", %{game: game} do
      game = Client.state(game.id)
      Client.next_stage(game.id)

      assert game.stage == "wait"
      assert length(game.players) < 2

      assert_receive %Phoenix.Socket.Broadcast{
        event: "error",
        payload: "At least two players are necessary to start the game."
      }
    end

    test "should broadcast the game when transition to next stage succeed", %{game: game} do
      player = build(:player, %{nick: "Aleph"})
      Client.join(game.id, player)

      Client.next_stage(game.id)

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

  describe "broadcast_game_error/2" do
    test "should broadcast the error as the payload and 'error' as event to the pubsub", %{game: game} do
      Phoenix.PubSub.subscribe(MemeGame.PubSub, MemeGame.PubSub.game_topic(game))

      MemeGame.GameServer.broadcast_game_error(game, :error)

      assert_receive %Phoenix.Socket.Broadcast{event: "error", payload: :error}
    end
  end
end
