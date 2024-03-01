defmodule MemeGame.GameServer.Client do
  @moduledoc """
    Provides an interface for calling or casting messages to MemeGame.GameServer.Server
  """

  alias MemeGame.Game
  alias MemeGame.Game.Player
  alias MemeGame.GameServer.ServerName

  @type game_id :: String.t()

  @spec state(game_id) :: Game.t() | {:error, atom()}
  def state(game_id) do
    call(game_id, :state)
  end

  @spec join(game_id, Player.t()) :: :ok
  def join(game_id, player) do
    cast(game_id, {:join, player})
  end

  @spec leave(game_id, Player.t()) :: :ok
  def leave(game_id, player) do
    cast(game_id, {:leave, player})
  end

  @spec next_stage(game_id) :: :ok
  def next_stage(game_id) do
    cast(game_id, :next_stage)
  end

  @spec cast(game_id, any()) :: :ok | {:error, :game_not_found}
  defp cast(game_id, message) do
    case game_pid(game_id) do
      {:ok, pid} -> GenServer.cast(pid, message)
      {:error, reason} -> {:error, reason}
    end
  end

  @spec call(game_id, any()) :: {:ok, any} | {:error, :atom}
  defp call(game_id, message) do
    case game_pid(game_id) do
      {:ok, pid} -> GenServer.call(pid, message)
      {:error, reason} -> {:error, reason}
    end
  end

  @spec game_pid(game_id) :: {:ok, pid()} | {:error, :game_not_found}
  defp game_pid(game_id) do
    case ServerName.get_game_pid(game_id) do
      {:ok, pid} -> {:ok, pid}
      _ -> {:error, :game_not_found}
    end
  end
end
