defmodule MemeGame.GameServer.Supervisor do
  @moduledoc """
      Supervisor responsible for creating and killing games
  """

  use DynamicSupervisor

  require Logger

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_new_game_server(String.t(), MemeGame.Game.Player.t(), String.t()) :: {:ok, pid()}
  def start_new_game_server(room_id, owner, locale \\ "en") do
    spec = {MemeGame.GameServer, %{room_id: room_id, owner: owner, locale: locale}}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_game_server(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
