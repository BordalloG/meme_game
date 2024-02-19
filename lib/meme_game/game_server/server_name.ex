defmodule MemeGame.GameServer.ServerName do
  @moduledoc """
      An interface over ETS to store and restore games id and PIDs
  """

  @table_name :server_name

  @spec put_game_pid(String.t(), pid()) :: true
  def put_game_pid(game_id, pid) do
    :ets.insert(@table_name, {game_id, pid})
  end

  @spec get_game_pid(String.t()) :: {atom(), pid()} | :error
  def get_game_pid(game_id) do
    case :ets.lookup(@table_name, game_id) do
      [{^game_id, pid}] -> {:ok, pid}
      _ -> :error
    end
  end

  @spec remove_game_pid(String.t()) :: boolean()
  def remove_game_pid(game_id) do
    :ets.delete(@table_name, game_id)
  end
end
