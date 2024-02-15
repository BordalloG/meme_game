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
end
