defmodule MemeGameWeb.GameLive do
  alias MemeGame.Game
  alias MemeGame.GameServer
  alias MemeGameWeb.Presence

  use MemeGameWeb, :live_view

  def mount(%{"game_id" => game_id} = _params, _session, socket) do
    socket =
      socket
      |> assign(:messages, [])

    game_topic = MemeGame.PubSub.game_topic(game_id)
    chat_topic = MemeGame.PubSub.chat_topic(game_id)

    if connected?(socket) && game_id do
      with {:ok, game} <- fetch_game(game_id),
           {:ok, game} <- join(game, socket.assigns.player) do
        Phoenix.PubSub.subscribe(MemeGame.PubSub, game_topic)
        Phoenix.PubSub.subscribe(MemeGame.PubSub, chat_topic)
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

        %Phoenix.Socket.Broadcast{event: "chat_message", payload: chat_message} ->
          assign(socket, :messages, socket.assigns.messages ++ [chat_message])
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
      MemeGame.PubSub.broadcast_chat_message(socket.assigns.game.id, message)

      {:noreply, push_event(socket, "clear", %{})}
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

      <div class="w-4/5 h-full flex flex-col bg-neutral-50 shadow-lg rounded text-center max-h-[90%] p-2 xl:flex-row">
        <%!-- game --%>
        <div class="w-full h-4/5 xl:w-4/5 xl:order-last xl:h-full">
          <.game game={@game} player={@player}/>
        </div>
        <%!-- lateral --%>
        <div class="w-full mt-4 h-1/5 xl:w-1/5 xl:h-full xl:max-h-full xl:mr-4 xl:mt-0">
          <div class="hidden xl:block xl:h-1/3 xl:w-full xl:h-1/3">
            <ul class="flex flex-col justify-center items-center text-center">
              <.player :for={p <- @game.players} game={@game} p={p} player={@player} />
            </ul>
          </div>
          <div class="flex flex-col justify-between rounded border-2 border-normal-400 h-full xl:h-2/3 xl:max-h-2/3 bg-neutral-100">
            <div class="overflow-y-scroll" id="chat" phx-hook="Scroll">
              <ul class="flex flex-col items-start">
                <.message
                  :for={message <- @messages}
                  text={message.text}
                  sender={message.sender}
                  player={@player}
                />
              </ul>
            </div>
            <div class="bg-normal-300 py-2 px-4">
              <.form class="flex justify-center" :let={_f} for={} phx-submit="send_message">
                <input
                  id="message_input"
                  type="text"
                  autocomplete="off"
                  name="message"
                  class="w-full h-8 p-2 bg-neutral-100 border-2 border-normal-700 border-r-transparent"
                  placeholder="Start Chatting ..."
                  phx-hook="MessageInput"
                />
                <button
                type="submit"
                class="bg-neutral-200 h-8 p-2 rounded-r-lg border-2 border-normal-700 border-l-transparent flex items-center justify-center">
                <.icon name="hero-chevron-right"/>
                </button>
              </.form>
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

  def player(assigns) do
    base_classes = "flex justify-center items-center w-3/4 my-2 rounded-lg py-1 bg-gradient-to-b shadow"
    others_players = "from-secondary-100 from-90% via-secondary-300 to-secondary-600"
    current_player = "from-primary-100 from-90% via-primary-300 to-primary-600 font-medium"

    classes = if(assigns.p == assigns.player) do
      current_player
    else
      others_players
    end

    assigns = assign(assigns, :classes, "#{base_classes} #{classes}")
    ~H"""
    <li
      class={@classes}
    >
      <span :if={@p == @game.owner} class="mr-2"><.crown /></span>
      <span> <%= @p.nick %> </span>
    </li>
    """
  end

  def message(assigns) do
    base_classes = "flex flex-col text-xs xl:text-base text-start bg-gradient-to-b from-90% p-2 m-2 max-w-[85%] shadow-md"
    others_classes = "rounded-e-xl rounded-es-xl from-secondary-100 to-secondary-400"
    sender_classes = "place-self-end rounded-none rounded-l-lg rounded-ee-xl from-primary-100 to-primary-400" #
    ~H"""
    <li class={if assigns.sender == assigns.player do "#{base_classes} #{sender_classes}" else "#{base_classes} #{others_classes}" end}>
      <span class="text-normal-900 font-bold"><%= @sender.nick %></span>
      <span class="text-normal-700"><%= @text %></span>
    </li>
    """
  end

  def game(assigns) do

    module = case assigns. game.stage do
      "wait" -> MemeGameWeb.Game.Stages.WaitComponent
      "design" -> MemeGameWeb.Game.Stages.DesignComponent
      "vote" -> MemeGameWeb.Game.Stages.VoteComponent
      "round_summary" -> MemeGameWeb.Game.Stages.RoundSummaryComponent
      "scoreboard" -> MemeGameWeb.Game.Stages.ScoreboardComponent
      "end" -> MemeGameWeb.Game.Stages.EndComponent
    end

    assigns = assign(assigns, :module, module)

    ~H"""
      <.live_component :if={@module} module={@module} id="game" game={@game} player={@player} />
    """
  end
end
