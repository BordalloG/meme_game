defmodule MemeGameWeb.HomeLive do
  use MemeGameWeb, :live_view

  def mount(params, _session, socket) do
    socket =
      if params["game_id"] do
        socket
        |> assign(:action, :existing)
        |> assign(:game_id, params["game_id"])
      else
        socket |> assign(:action, :new) |> assign(:game_id, 0)
      end

    {:ok, socket}
  end

  def handle_event("toggle_action", _unsigned_params, socket) do
    socket =
      socket
      |> assign(:game_id, "")
      |> assign(:action, :existing)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    <div class="h-screen flex flex-col justify-between items-center bg-[#EBEBEB]">
      <.top_wave />
      <div class="flex flex-col md:flex-row justify-center items-center">
        <h1 class="mb-4 text-6xl text-center font-extrabold leading-none tracking-tight md:text-7xl lg:text-8xl bg-gradient-to-b from-accent-500 from-60% to-accent-600 text-transparent bg-clip-text">
          Meme Game
        </h1>
        <div class="md:basis-4/5">
          <.form :let={f} for={} action={~p"/"}>
            <label class="my-6 text-normal-700 font-bold text-lg font-mono"> Nick: </label>
            <.input field={f[:nick]} type="text" id="nick" autocomplete="off" required />
            <.game_field :if={@action != :new} f={f} game_id={@game_id} />
            <div class="flex my-4 justify-between items-center flex-col md:flex-row">
              <.actions action={@action} />
            </div>
          </.form>
        </div>
      </div>
      <.bottom_wave />
    </div>
    """
  end

  def actions(assigns) do
    ~H"""
    <button
      type="submit"
      class="py-2 shadow-md basis-5/12 rounded-lg w-full bg-gradient-to-b from-primary-100 from-90% via-primary-300 to-primary-600 text-normal-900 hover:bg-gradient-to-b hover:from-primary-100 hover:from-90% hover:via-primary-700 hover:to-primary-800 hover:-translate-y-1 hover:origin-top-left hover:-rotate-1 hover:shadow-lg hover:shadow-primary-700/100 duration-300"
    >
      <%= gettext("New Game") %>
    </button>
    <p class="text-normal-700">
      <%= gettext("or") %>
    </p>
    <button
      :if={@action == :new}
      type="button"
      phx-click="toggle_action"
      class="py-2 shadow-md basis-5/12 rounded-lg w-full bg-gradient-to-b from-secondary-100 from-90% via-secondary-300 to-secondary-600 text-normal-900 hover:bg-gradient-to-b hover:from-secondary-100 hover:from-90% hover:via-secondary-700 hover:to-secondary-800 hover:-translate-y-1 hover:origin-top-left hover:rotate-1 hover:shadow-lg hover:shadow-secondary-700/100 duration-300"
    >
      <%= gettext("Existing Game") %>
    </button>
    <button
      :if={@action != :new}
      type="submit"
      class="py-2 shadow-md basis-5/12 rounded-lg w-full bg-gradient-to-b from-secondary-100 from-90% via-secondary-300 to-secondary-600 text-normal-900 hover:bg-gradient-to-b hover:from-secondary-100 hover:from-90% hover:via-secondary-700 hover:to-secondary-800 hover:-translate-y-1 hover:origin-top-left hover:rotate-1 hover:shadow-lg hover:shadow-secondary-700/100 duration-300"
    >
      <%= gettext("Existing Game") %>
    </button>
    """
  end

  def game_field(assigns) do
    ~H"""
    <label class="my-6 text-normal-700 font-bold text-lg font-mono"> Game: </label>
    <.input
      field={@f[:game_id]}
      type="text"
      id="game_id"
      autocomplete="off"
      value={@game_id}
    />
    """
  end

  def top_wave(assigns) do
    ~H"""
    <div class="bg-bottom bg-top_wave bg-cover bg-no-repeat w-full h-2/6"></div>
    """
  end

  def bottom_wave(assigns) do
    ~H"""
    <div class="bg-top bg-bottom_wave bg-cover bg-no-repeat w-full h-2/6"></div>
    """
  end
end
