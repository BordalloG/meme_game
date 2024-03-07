defmodule MemeGameWeb.Game.InspectLive do
  alias MemeGame.Game
  alias MemeGame.GameServer
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

  def fetch_game(game_id) do
    case GameServer.Client.state(game_id) do
      %Game{} = game -> {:ok, %{game: game}}
      {:error, reason} -> {:error, reason}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-row w-full">
      <div class="basis-1/3">
        <.async_result :let={game} assign={@game}>
          <:loading>Loading Game ... </:loading>
          <:failed :let={failure}><%= inspect failure %></:failed>
          <.game game={game}/>
        </.async_result>
      </div>
      <div class="basis-2/3 p-4 rounded bg-slate-200 h-96 max-h-96 overflow-scroll">
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
    <div class="flex justify-around">
      <button class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" phx-click="next_stage"> Next Stage </button>
    </div>
    """
  end

  def game(assigns) do
    ~H"""
     id: <%= @game.id %> <br/>
     owner: <%= @game.owner.nick %> <br/>
     stage: <%= @game.stage %> <br>
     players:<%= Enum.map(@game.players, fn p -> "[#{p.id}] #{p.nick}"  end) %>
    """
  end
end
