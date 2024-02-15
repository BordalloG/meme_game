defmodule MemeGame.GameTest do
  use MemeGame.DataCase
  use ExUnit.Case, async: true

  import MemeGame.Factory

  alias MemeGame.Game

  describe "next_stage/1" do
    test "wait -> design when transition is valid" do
      game = build(:game, %{stage: "wait"})

      {:ok, updated_game} = Game.next_stage(game)

      assert updated_game.stage == "design"
    end

    test "wait -> error when there aren't enought players" do
      owner = build(:player)
      game = build(:game, %{stage: "wait", owner: owner, players: [owner]})

      assert length(game.players) < 2

      assert {:error, "At least two players are necessary to start the game."} =
               Game.next_stage(game)
    end

    test "design -> vote when transition is valid" do
      game = build(:game, %{stage: "design"})

      {:ok, updated_game} = Game.next_stage(game)

      assert updated_game.stage == "vote"
    end

    test "vote -> round_summary when transition is valid" do
      game = build(:game, %{stage: "vote"})

      {:ok, updated_game} = Game.next_stage(game)

      assert updated_game.stage == "round_summary"
    end

    test "round_summary -> scoreboard when transition is valid" do
      game = build(:game, %{stage: "round_summary"})

      {:ok, updated_game} = Game.next_stage(game)

      assert updated_game.stage == "scoreboard"
    end

    test "scoreboard -> wait when transition is valid" do
      game = build(:game, %{stage: "scoreboard"})

      {:ok, updated_game} = Game.next_stage(game)

      assert updated_game.stage == "wait"
    end
  end

  describe "can_join?/2" do
    test "a valid player should be able to join the game" do
      owner = build(:player)
      game = build(:game, %{owner: owner, players: [owner]})
      new_player = build(:player, %{nick: "John"})

      assert {:ok, _game} = MemeGame.Game.can_join?(game, new_player)
    end

    test "a new player should not be able to join when game room is full" do
      owner = build(:player)
      game_settings = build(:settings)

      game =
        build(
          :game,
          %{owner: owner, players: [owner] ++ build_list(game_settings.max_players, :player)}
        )

      new_player = build(:player, %{nick: "Beth"})

      assert {:error, ["Game is already full"]} = MemeGame.Game.can_join?(game, new_player)
    end

    test "a new player should not be able to join when it's nick is empty" do
      game = build(:game)

      new_players =
        [build(:player, %{nick: ""}), build(:player, %{nick: " "}), build(:player, %{nick: "  "})]

      expected_error = {:error, ["Empty nicks are not allowed"]}

      Enum.each(new_players, fn new_player ->
        assert expected_error == MemeGame.Game.can_join?(game, new_player)
      end)
    end

    test "a new player should not be able to join with a nick of another player" do
      game = build(:game)
      new_player = build(:player, %{nick: game.owner.nick})

      assert {:error, ["This nick is already in use"]} ==
               MemeGame.Game.can_join?(game, new_player)
    end
  end
end
