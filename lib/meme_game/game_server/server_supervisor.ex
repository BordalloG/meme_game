defmodule MemeGame.GameServer.Supervisor do
  @moduledoc """
      Supervisor responsible for creating and killing games
  """

  use DynamicSupervisor

  require Logger

  alias MemeGame.GameServer.ServerName

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_new_game_server(String.t(), MemeGame.Game.Player.t(), String.t()) ::
          {:ok, pid()} | {:error, String.t()}
  def start_new_game_server(game_id, owner, locale \\ "en") do
    spec = {MemeGame.GameServer, %{game_id: game_id, owner: owner, locale: locale}}

    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, spec)

    ServerName.put_game_pid(game_id, pid)
    {:ok, pid}
  end

  def stop_game_server(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
