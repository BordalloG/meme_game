defmodule MemeGameWeb.GameLive do
  alias MemeGame.Game
  alias MemeGame.GameServer
  alias MemeGameWeb.Presence

  use MemeGameWeb, :live_view

  def mount(%{"game_id" => game_id} = _params, _session, socket) do
    socket =
      socket
      |> assign(:messages, [])

    topic = MemeGame.PubSub.game_topic(game_id)

    if connected?(socket) && game_id do
      with {:ok, game} <- fetch_game(game_id),
           {:ok, game} <- join(game, socket.assigns.player) do
        Phoenix.PubSub.subscribe(MemeGame.PubSub, topic)
        {:ok, assign(socket, :game, game)}
      else
        {:error, reasons} when is_list(reasons) ->
          redirect_home(socket, :error, Enum.join(reasons, ""))

        {:error, reason} ->
          redirect_home(socket, :error, reason)
      end
    else
      {:ok, socket}
    end
  end

  @spec fetch_game(binary()) :: {:ok, Game.t()} | {:error, :atom}
  def fetch_game(game_id) do
    case GameServer.Client.state(game_id) do
      %Game{} = game -> {:ok, game}
      {:error, reason} -> {:error, reason}
    end
  end

  def join(game, player) do
    case GameServer.Client.join(game.id, player) do
      {:ok, game} ->
        Presence.track_user(self(), game.id, player.id, player)
        {:ok, game}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def redirect_home(socket, :error, error) do
    socket =
      socket
      # TODO: Turn atom into text ~> Gettext?
      |> put_flash(:error, error)
      |> redirect(to: "/")

    {:ok, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: _event, payload: _payload} = message, socket) do
    socket =
      case message do
        %Phoenix.Socket.Broadcast{event: "update", payload: game} ->
          assign(socket, :game, game)

        %Phoenix.Socket.Broadcast{event: "error", payload: error} ->
          put_flash(socket, :error, error)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("send_message", %{"message" => text}, socket) do
    if String.trim(text) == "" do
      {:noreply, socket}
    else
      message = %{sender: socket.assigns.player, text: text}
      {:noreply, assign(socket, :messages, [message | socket.assigns.messages])}
    end
  end

  def render(%{game: _game} = assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center h-screen p-4">
      <div class="w-4/5 mb-4 flex justify-between">
        <div class="w-1/3 py-2 rounded-l">
          <span class="rounded-l-lg bg-secondary-500 py-1 px-2 border-y border-l border-normal-800">
            <%= @game.current_round %>
          </span>
          <span class="rounded-r-lg bg-secondary-200 py-1 px-2 border-y border-r border-normal-800">
            <%= @game.stage %>
          </span>
        </div>
        <div class="bg-normal-50 w-1/3 py-2 rounded-r"></div>
      </div>

      <div class="w-4/5 h-full flex flex-col bg-neutral-50 shadow-lg rounded text-center p-2 xl:flex-row">
        <%!-- game --%>
        <div class="w-full h-4/5 xl:w-4/5 xl:order-last xl:h-full">
          GAME
        </div>
        <%!-- lateral --%>
        <div class="w-full mt-4 h-1/5 xl:w-1/5 xl:h-full xl:mr-4 xl:mt-0">
          <div class="hidden xl:block xl:h-1/3 xl:w-full xl:h-1/3">
            <ul class="flex flex-col justify-center items-center text-center">
              <li
                :for={player <- @game.players}
                class="flex justify-center items-center w-3/4 my-2 rounded-lg py-1 bg-gradient-to-b from-primary-100 from-90% via-primary-300 to-primary-600 shadow"
              >
                <span :if={player == @game.owner} class="mr-2"><.crown /></span>
                <span><%= player.nick %></span>
              </li>
            </ul>
          </div>
          <div class="flex flex-col justify-between rounded border-2 border-secondary-400 h-full xl:h-2/3 bg-neutral-100">
            <div class="max-h-1/3 overflow-y-auto">
              <ul class="flex flex-col items-start">
                <.message
                  :for={message <- @messages}
                  text={message.text}
                  sender={message.sender}
                  player={@player}
                />
                <.message text="Sample 123" sender={@game.owner} player={@player} />
                <.message text="S" sender={@game.owner} player={@player} />
                <.message text="is it a sample??" sender={@game.owner} player={@player} />
              </ul>
            </div>
            <div class="bg-secondary-500 py-2 px-4">
              <form class="flex justify-center" phx-submit="send_message">
                <input
                  type="text"
                  name="message"
                  class="w-full h-8 p-2 bg-neutral-100 border-2 border-secondary-700 border-r-transparent"
                  placeholder="Start Chatting ..."
                />
                <button class="bg-neutral-200 h-8 p-2 rounded-r-lg border-2 border-secondary-700 border-l-transparent">
                  <.icon name="hero-paper-airplane-solid" />
                </button>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    Loading...
    """
  end

  def message(assigns) do
    classes =
      "flex flex-col text-start bg-gradient-to-b from-secondary-100 from-90% to-secondary-400 p-2 m-2 max-w-[85%] rounded shadow-md"

    ~H"""
    <li class={
      if @sender == @player do
        classes <> " place-self-end"
      else
        classes
      end
    }>
      <span class="text-secondary-900 font-bold"><%= @sender.nick %></span>
      <span class="text-normal-900"><%= @text %></span>
    </li>
    """
  end
end
