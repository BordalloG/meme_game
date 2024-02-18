defmodule MemeGame.GameServer.ServerNameTest do
  use ExUnit.Case
  alias MemeGame.GameServer.ServerName

  describe "put_game_pid/2" do
    test "successfully inserts a game ID and PID into the ETS table" do
      game_id = "game_123"
      pid = self()
      assert ServerName.put_game_pid(game_id, pid) == true
    end
  end

  describe "get_game_pid/1" do
    test "retrieves the PID for a given game ID" do
      game_id = "game_123"
      pid = self()
      ServerName.put_game_pid(game_id, pid)
      assert ServerName.get_game_pid(game_id) == {:ok, pid}
    end

    test "returns :error if the game ID does not exist" do
      assert ServerName.get_game_pid("nonexistent_game") == :error
    end
  end

  describe "remove_game_pid/1" do
    test "successfully removes a game ID and its associated PID from the ETS table" do
      game_id = "game_123"
      pid = self()
      ServerName.put_game_pid(game_id, pid)
      assert ServerName.remove_game_pid(game_id) == true
      assert ServerName.get_game_pid(game_id) == :error
    end
  end
end
