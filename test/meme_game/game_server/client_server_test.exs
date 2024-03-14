defmodule MemeGame.ClientServerTest do
  use MemeGame.DataCase
  use ExUnit.Case, async: true

  alias MemeGame.Game
  alias MemeGame.GameServer.Client

  import MemeGame.Factory

  setup do
    game = build(:game)
    {:ok, pid} = MemeGame.GameServer.Supervisor.start_new_game_server(game.id, game.owner)

    Phoenix.PubSub.subscribe(MemeGame.PubSub, MemeGame.PubSub.game_topic(game))
    on_exit(fn -> MemeGame.GameServer.Supervisor.stop_game_server(game.id) end)
    {:ok, %{game: game, pid: pid}}
  end

  describe "init" do
    test "starting a game should add owner as a player" do
      game = build(:game, %{id: "different_id"})
      {:ok, _pid} = MemeGame.GameServer.Supervisor.start_new_game_server(game.id, game.owner)

      game = Client.state(game.id)

      assert Enum.any?(game.players, fn p -> p == game.owner end)
      assert length(game.players) == 1
    end
  end

  describe "state/1" do
    test "should return current game state", %{game: game} do
      assert %MemeGame.Game{} = response = Client.state(game.id)
      assert response.id == game.id
      assert response.owner == game.owner
    end
  end

  describe "join/2" do
    test "should add a player to the players list", %{game: game} do
      player = build(:player)

      Client.join(game.id, player)

      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: payload}
      assert Enum.any?(payload.players, fn p -> p == player end)
    end

    test "should not add a player when room is full", %{game: game} do
      Enum.each(1..(game.settings.max_players - 1), fn i ->
        player = build(:player, %{id: "#{i}", nick: "Player#{i}"})
        Client.join(game.id, player)
        assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _payload}
      end)

      player = build(:player, %{id: "007", nick: "James"})
      Client.join(game.id, player)
      assert_receive %Phoenix.Socket.Broadcast{event: "error", payload: "Game is full"}
    end
  end

  describe "leave/2" do
    test "should remove a player from the players list", %{game: game} do
      player = build(:player, %{id: "abcd", nick: "Philip"})

      Client.leave(game.id, player)

      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: payload}
      refute Enum.any?(payload.players, fn p -> p == player end)
    end

    test "should nominate a new owner when the current owner leaves", %{game: game} do
      player = build(:player, %{id: "abcd", nick: "Philip"})
      Client.join(game.id, player)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _payload}

      Client.leave(game.id, game.owner)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: payload}

      refute Enum.any?(payload.players, fn p -> p == game.owner end)
      assert payload.owner == player
    end

    test "should end game with there is no players left", %{game: game} do
      Client.leave(game.id, game.owner)
      assert_receive %Phoenix.Socket.Broadcast{event: "end", payload: message}
      assert message == "no players left"
    end
  end

  describe "next_stage/1" do
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

  describe "submit_meme/2" do
    test "should append the meme in the list of memes for the current round", %{game: game} do
      # add a new player, otherwise we can't transtition to design stage
      Client.join(game.id, build(:player))
      # go to design stage
      Client.next_stage(game.id)

      meme = build(:meme)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _join_response}
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _next_stage_response}

      Client.submit_meme(game.id, meme)

      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: game}

      current_round = Game.current_round(game)
      assert Enum.any?(current_round.memes, fn m -> m == meme end)
    end

    test "should discart the meme if current stage is not design", %{game: game} do
      meme = build(:meme)
      Client.submit_meme(game.id, meme)

      assert_receive %Phoenix.Socket.Broadcast{
        event: "error",
        payload: "Memes can only be submitted during the design stage."
      }
    end

    test "should discart the meme if the player has already sent a meme for the current round", %{
      game: game
    } do
      player = build(:player, %{id: "123"})
      # add a new player, otherwise we can't transtition to design stage
      Client.join(game.id, player)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _join_response}
      # go to design stage
      Client.next_stage(game.id)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _next_stage_response}

      meme = build(:meme, %{owner: player})
      Client.submit_meme(game.id, meme)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: game}

      Client.submit_meme(game.id, meme)

      assert_receive %Phoenix.Socket.Broadcast{
        event: "error",
        payload: "You can send only one meme per round"
      }

      current_round = Game.current_round(game)
      assert Enum.any?(current_round.memes, fn m -> m == meme end)
    end

    test "should transition to the next stage when the meme received was the last one possible",
         %{game: game} do
      player = build(:player, %{id: "123"})
      # add a new player, otherwise we can't transtition to design stage
      Client.join(game.id, player)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _join_response}
      # go to design stage
      Client.next_stage(game.id)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _next_stage_response}

      meme1 = build(:meme, %{owner: player})
      Client.submit_meme(game.id, meme1)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: game}

      meme2 = build(:meme, %{owner: game.owner})
      Client.submit_meme(game.id, meme2)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: game}

      assert game.stage == "vote"
    end
  end

  describe "vote_meme" do
    test "should add a vote to a meme", %{game: game} do
      owner = game.owner
      player = build(:player, %{id: "ABC", nick: "Phil"})
      player2 = build(:player, %{id: "abc", nick: "Loren"})

      Client.join(game.id, player)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _join}
      Client.join(game.id, player2)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _join}

      Client.next_stage(game.id)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: game}
      assert game.stage == "design"

      owner_meme = build(:meme, %{owner: owner})
      player_meme = build(:meme, %{owner: player})
      player2_meme = build(:meme, %{owner: player2})

      # each player send a meme
      Client.submit_meme(game.id, owner_meme)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _game}

      Client.submit_meme(game.id, player_meme)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _game}

      Client.submit_meme(game.id, player2_meme)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: game}
      # it should go to next stage by itself
      assert game.stage == "vote"

      # voting owner meme
      Client.vote(game.id, player, owner_meme, :up)
      Client.vote(game.id, player2, owner_meme, :mid)

      # #voting player meme
      Client.vote(game.id, owner, player_meme, :up)
      Client.vote(game.id, player2, player_meme, :mid)

      # #voting player 2 meme
      Client.vote(game.id, player, player2_meme, :up)
      Client.vote(game.id, owner, player2_meme, :mid)

      Client.next_stage(game.id)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: game}
      assert game.stage == "round_summary"

      current_round = Game.current_round(game)
      memes = current_round.memes

      Enum.each(memes, fn m -> assert length(m.votes) == 2 end)
    end

    test "should not allow player vote on own meme", %{game: game} do
      owner = game.owner
      player = build(:player, %{id: "ABC", nick: "Phil"})

      Client.join(game.id, player)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _join}

      Client.next_stage(game.id)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: game}
      assert game.stage == "design"

      owner_meme = build(:meme, %{owner: owner})
      player_meme = build(:meme, %{owner: player})

      Client.submit_meme(game.id, owner_meme)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _game}

      Client.submit_meme(game.id, player_meme)
      assert_receive %Phoenix.Socket.Broadcast{event: "update", payload: _game}

      Client.vote(game.id, owner, owner_meme, :up)

      assert_receive %Phoenix.Socket.Broadcast{
        event: "error",
        payload: "You cannot vote your own meme"
      }
    end

    test "should only allow votes to meme in vote stage and in the correct round", %{game: game} do
      player = build(:player, %{id: "abcd", nick: "Phil"})
      owner_meme = build(:meme, %{owner: game.owner})

      Client.vote(game.id, player, owner_meme, :up)

      assert_receive %Phoenix.Socket.Broadcast{
        event: "error",
        payload: "Votes are only allowed during the vote stage"
      }
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
    test "should broadcast the error as the payload and 'error' as event to the pubsub", %{
      game: game
    } do
      Phoenix.PubSub.subscribe(MemeGame.PubSub, MemeGame.PubSub.game_topic(game))

      MemeGame.GameServer.broadcast_game_error(game, :error)

      assert_receive %Phoenix.Socket.Broadcast{event: "error", payload: :error}
    end
  end
end
