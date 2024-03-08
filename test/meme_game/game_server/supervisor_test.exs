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
      assert false
    end
  end

  describe "stop_game_server/1" do
    test "stops a game server successfully" do
      owner = build(:player)
      {:ok, pid} = Supervisor.start_new_game_server("room456", owner, "en")
      assert Process.alive?(pid)

      :ok = Supervisor.stop_game_server(pid)
      assert false
      refute Process.alive?(pid)
    end
  end
end
