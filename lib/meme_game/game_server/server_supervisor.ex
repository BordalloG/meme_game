defmodule MemeGame.GameServer.Supervisor do
  @moduledoc """
      Supervisor responsible for creating and killing games
  """

  use DynamicSupervisor

  require Logger

  alias MemeGame.GameServer.ServerName

  import MemeGameWeb.Gettext

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

    case ServerName.get_game_pid(game_id) do
      {:ok, _pid} ->
        {:error, "#{dgettext("errors", "Game already exists")} game_id: #{game_id}"}

      _ ->
        {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, spec)
        ServerName.put_game_pid(game_id, pid)
        {:ok, pid}
    end
  end

  @spec stop_game_server(String.t()) :: {:ok, pid()} | :error
  def stop_game_server(game_id) do
    case ServerName.get_game_pid(game_id) do
      {:ok, pid} ->
        :ok = DynamicSupervisor.terminate_child(__MODULE__, pid)
        ServerName.remove_game_pid(game_id)
        :ok

      reason ->
        Logger.error("Could not stop game server #{game_id} with reason #{inspect(reason)}")
        :error
    end
  end
end
