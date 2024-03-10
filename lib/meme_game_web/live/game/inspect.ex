defmodule MemeGameWeb.Game.InspectLive do
  alias MemeGame.Game
  alias MemeGame.GameServer
  alias MemeGame.GameServer.Supervisor

  use MemeGameWeb, :live_view

  def handle_params(%{"game_id" => game_id}, _uri, socket) do
    if connected?(socket) do
      topic = MemeGame.PubSub.game_topic(game_id)

      Phoenix.PubSub.subscribe(MemeGame.PubSub, topic)
    end

    socket =
      socket
      |> assign(:game_id, game_id)
      |> assign(:messages, [])
      |> assign_async(:game, fn -> fetch_game(game_id) end)

    {:noreply, assign(socket, game_id: game_id)}
  end

  @spec handle_info(Phoenix.Socket.Broadcast.t(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info(%Phoenix.Socket.Broadcast{event: _event, payload: _payload} = message, socket) do
    socket = assign(socket, messages: [message | socket.assigns.messages])
    {:noreply, socket}
  end

  def handle_event("next_stage", _params, socket) do
    GameServer.Client.next_stage(socket.assigns.game_id)
    {:noreply, socket}
  end

  def handle_event("create_game", _params, socket) do
    game_id = socket.assigns.game_id

    Supervisor.start_new_game_server(
      game_id,
      %MemeGame.Game.Player{id: "123", nick: "John"},
      "en"
    )

    socket =
      socket
      |> assign_async(:game, fn -> fetch_game(game_id) end)

    {:noreply, socket}
  end

  def handle_event("stop_game", _params, socket) do
    game_id = socket.assigns.game_id

    socket =
      case Supervisor.stop_game_server(game_id) do
        :ok ->
          socket
          |> assign_async(:game, fn -> fetch_game(game_id) end, reset: true)

        :error ->
          socket
      end

    {:noreply, socket}
  end

  def fetch_game(game_id) do
    case GameServer.Client.state(game_id) do
      %Game{} = game -> {:ok, %{game: game}}
      {:error, reason} -> {:error, reason}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="w-full">
      <div
        id="game_info"
        class="w-full min-w-max flex justify-around bg-neutral-100 rounded py-3 drop-shadow-lg items-center mb-4"
      >
        <.async_result :let={game} assign={@game}>
          <:loading>Loading Game ...</:loading>
          <:failed :let={failure}><.failure failure={failure} game_id={@game_id} /></:failed>
          <.game game={game} />
        </.async_result>
      </div>

      <div class="flex justify-around">
        <button
          class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          phx-click="next_stage"
        >
          Next Stage
        </button>
      </div>

      <div class="basis-1/2 p-4 rounded bg-slate-200 h-96 max-h-96 overflow-scroll">
        <p id="messages_count">[<%= length(@messages) %>] Messages:</p>
        <div
          :for={message <- @messages}
          class="border-dashed border-2 border-slate-500 rounded p-1 mb-2"
        >
          <p class="p-1 bg-slate-300 rounded">Event: <%= inspect(message.event) %></p>
          <p class="p-1 mt-2 bg-slate-100 rounded"><%= inspect(message.payload) %></p>
        </div>
      </div>
    </div>
    """
  end

  def failure(%{failure: {:error, :game_not_found}} = assigns) do
    ~H"""
    Game <%= @game_id %> not found.
    <button
      id="create_game"
      class="border-2 border-teal-600 hover:bg-teal-600 text-teal-600 hover:text-white font-bold py-1 px-2 rounded"
      phx-click="create_game"
    >
      Create Game
    </button>
    """
  end

  def failure(assigns) do
    ~H"""
    Something went wrong: <%= inspect(@failure) %>
    """
  end

  def game(assigns) do
    ~H"""
    <.game_info title="Game" value={@game.id} />
    <.game_info title="Round" value={"[#{@game.current_round}/#{@game.settings.rounds}]"} />
    <.game_info title="Stage" value={@game.stage} />
    <.game_info title="Players" value={"[#{length(@game.players)}/#{@game.settings.max_players}]"} />
    <button
      id="kill_game"
      class="border-2 border-red-700 hover:bg-red-700 text-red-700 hover:text-white font-bold py-1 px-2 rounded"
      phx-click="stop_game"
    >
      Kill Game
    </button>
    """
  end

  def game_info(assigns) do
    ~H"""
    <p id={"info_#{String.downcase(@title)}"} class="font-bold text-center">
      <%= @title %>
      <span class="font-normal text-center block">
        <%= @value %>
      </span>
    </p>
    """
  end
end
