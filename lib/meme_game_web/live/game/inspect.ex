defmodule MemeGameWeb.Game.InspectLive do
  alias MemeGame.Game
  alias MemeGame.Game.Player
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
    socket =
      case message do
        %Phoenix.Socket.Broadcast{event: "update", payload: game} ->
          assign_async(socket, :game, fn -> {:ok, %{game: game}} end)

        %Phoenix.Socket.Broadcast{event: "error", payload: error} ->
          put_flash(socket, :error, error)

        %Phoenix.Socket.Broadcast{event: "end", payload: message} ->
          put_flash(socket, :info, message)
          |> assign_async(:game, fn -> fetch_game(socket.assigns.game_id) end, reset: true)
          |> push_patch(to: ~p"/game/#{socket.assigns.game_id}/inspect")

        _ ->
          socket
      end

    socket = assign(socket, messages: [message | socket.assigns.messages])
    {:noreply, socket}
  end

  def handle_event("next_stage", _params, socket) do
    GameServer.Client.next_stage(socket.assigns.game_id)
    {:noreply, socket}
  end

  def handle_event("join", _params, socket) do
    id = "#{length(socket.assigns.game.result.players) + 1}"
    nick = "Player #{id}"

    GameServer.Client.join(socket.assigns.game_id, %Player{id: id, nick: nick})
    {:noreply, socket}
  end

  def handle_event("kick", %{"id" => id, "nick" => nick}, socket) do
    GameServer.Client.leave(socket.assigns.game_id, %Player{id: id, nick: nick})
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

  def handle_event("kill_game", _params, socket) do
    game_id = socket.assigns.game_id

    socket =
      case Supervisor.stop_game_server(game_id) do
        :ok ->
          socket
          |> assign_async(:game, fn -> fetch_game(game_id) end, reset: true)
          |> push_patch(to: ~p"/game/#{game_id}/inspect")

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
    <.async_result :let={game} assign={@game}>
      <:loading>Loading Game ...</:loading>
      <:failed :let={failure}>
        <.failure failure={failure} game_id={@game_id} />
      </:failed>
      <.success game={game} messages={@messages} />
    </.async_result>
    """
  end

  def success(assigns) do
    ~H"""
    <.game game={@game} />
    <div class="flex w-full justify-between">
      <div id="left" class="basis-4/12 w-full">
        <.players players={@game.players} owner={@game.owner} />
      </div>
      <div id="right" class="basis-6/12">
        <.actions />
        <.messages messages={@messages} />
      </div>
    </div>
    """
  end

  def failure(%{failure: {:error, :game_not_found}} = assigns) do
    ~H"""
    <h1 class="text-red-700 font-bold text-3xl">Game <%= @game_id %> does not exist.</h1>
    <button
      id="create_game"
      class="text-neutal-800 hover:text-neutal-800 hover:underline"
      phx-click="create_game"
    >
      Create a new Game with this id.
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
    <div
      id="game_info"
      class="w-full min-w-max flex justify-around bg-neutral-100 rounded py-3 drop-shadow-lg items-center mb-4"
    >
      <.game_info id="game" title="Game" value={@game.id} />
      <.game_info
        id="round"
        title="Round"
        value={"[#{@game.current_round}/#{@game.settings.rounds}]"}
      />
      <.game_info id="stage" title="Stage" value={@game.stage} />
      <.game_info
        id="players"
        title="Players"
        value={"[#{length(@game.players)}/#{@game.settings.max_players}]"}
      />
      <button
        id="kill_game"
        class="border-2 border-red-700 hover:bg-red-700 text-red-700 hover:text-white font-bold py-1 px-2 rounded"
        phx-click="kill_game"
      >
        Kill Game
      </button>
    </div>
    """
  end

  def actions(assigns) do
    ~H"""
    <div
      id="game_info"
      class="w-full min-w-max flex justify-around bg-neutral-100 rounded py-3 drop-shadow-lg items-center mb-4"
    >
      <button
        class="border-2 border-neutral-600 hover:bg-neutral-600 text-neutral-600 hover:text-white font-bold py-1 px-2 rounded"
        phx-click="next_stage"
      >
        Next Stage
      </button>
      <button
        class="border-2 border-neutral-600 hover:bg-neutral-600 text-neutral-600 hover:text-white font-bold py-1 px-2 rounded"
        phx-click="join"
      >
        Add Player
      </button>
    </div>
    """
  end

  def messages(assigns) do
    ~H"""
    <div class="basis-1/2 p-4 rounded bg-slate-200 h-96 max-h-96 overflow-y-scroll">
      <p id="messages_count">[<%= length(@messages) %>] Messages:</p>
      <div
        :for={message <- @messages}
        class="border-dashed border-2 border-slate-500 rounded p-1 mb-2"
      >
        <p class={"p-1 rounded #{if message.event == "error" do "bg-red-200" else "bg-slate-300" end}"}>
          Event: <%= inspect(message.event) %>
        </p>
        <p class="p-1 mt-2 bg-slate-100 rounded"><%= inspect(message.payload, pretty: true) %></p>
      </div>
    </div>
    """
  end

  def players(assigns) do
    ~H"""
    <div class="w-full flex flex-col justify-around bg-neutral-100 rounded p-3 drop-shadow-lg items-center mb-4">
      <h1><b> Players </b></h1>
      <ul class="w-full">
        <li :for={p <- @players} class="flex">
          <span class="flex basis-1/12 justify-center items-center">
            <.crown :if={p == @owner} />
          </span>
          <span class="flex justify-start  basis-11/12">
            [<%= p.id %>] <%= p.nick %>
          </span>
          <button class="hover:underline" phx-click="kick" phx-value-id={p.id} phx-value-nick={p.nick}>
            kick
          </button>
        </li>
      </ul>
    </div>
    """
  end

  def game_info(assigns) do
    ~H"""
    <p id={"info_#{@id}"} class="font-bold text-center">
      <%= @title %>
      <span class="font-normal text-center block">
        <%= @value %>
      </span>
    </p>
    """
  end
end
