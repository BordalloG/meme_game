defmodule MemeGame.SupervisorTest do
  use MemeGame.DataCase
  use ExUnit.Case, async: true

  import MemeGame.Factory

  alias MemeGame.GameServer.Supervisor

  describe "start_new_game_server/3" do
    test "starts a new game server successfully" do
      owner = build(:player)

      {:ok, pid} = Supervisor.start_new_game_server("123", owner, "en")

      assert Process.alive?(pid)
    end

    test "should not start a new game server with a game id in use" do
      owner = build(:player)
      game_id = "1234"

      {:ok, pid} = Supervisor.start_new_game_server(game_id, owner, "en")

      assert Process.alive?(pid)
      assert {:error, reason} = Supervisor.start_new_game_server(game_id, owner, "en")
      assert reason == :game_already_exist
    end
  end

  describe "stop_game_server/1" do
    test "stops a game server successfully" do
      owner = build(:player)
      game_id = "game456"

      {:ok, pid} = Supervisor.start_new_game_server(game_id, owner, "en")
      assert Process.alive?(pid)

      :ok = Supervisor.stop_game_server(game_id)
      refute Process.alive?(pid)
    end
  end
end
