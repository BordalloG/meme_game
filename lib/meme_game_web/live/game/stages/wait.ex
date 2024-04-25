defmodule MemeGameWeb.Game.Stages.WaitComponent do
  use MemeGameWeb, :live_component

  def handle_event("start_game", _, socket) do
    MemeGame.GameServer.Client.next_stage(socket.assigns.game.id)
    {:noreply, socket}
  end
  def render(assigns) do
    ~H"""
      <div class="flex justify-center items-center w-full h-full">
        <button :if={@player == @game.owner}
          class=
          "py-2 shadow-md basis-2/4 lg:basis-1/3 xl:basis-1/4 rounded-lg w-full bg-gradient-to-b
          from-sky-300 from-90% via-sky-700 to-sky-800 text-normal-900 duration-300
          hover:-translate-y-1 hover:shadow-lg hover:shadow-sky-300/50 hover:font-semibold"
          phx-click="start_game"
          phx-target={@myself}
          >
            Start Game
        </button>
        <p :if={@player != @game.owner}>
          Waiting Owner to Start the Game
        </p>
      </div>
    """
  end
end
