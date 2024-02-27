defmodule MemeGameWeb.Game.InspectLive do
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
      |> assign(:game, %MemeGame.Game{id: game_id})

    {:noreply, assign(socket, game_id: game_id)}
  end

  @spec handle_info(Phoenix.Socket.Broadcast.t(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info(%Phoenix.Socket.Broadcast{event: _event, payload: _payload} = message, socket) do
    socket = assign(socket, messages: [message | socket.assigns.messages])
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Inspecting Game <%= @game_id %></h1>
    <p id="messages_count">[<%= length(@messages) %>] Messages:</p>
    <div class="p-4 rounded bg-slate-200 h-96 max-h-96 overflow-scroll">
      <div
        :for={message <- @messages}
        class="border-dashed border-2 border-slate-500 rounded p-1 mb-2"
      >
        <p class="p-1 bg-slate-300 rounded">Event: <%= inspect(message.event) %></p>
        <p class="p-1 mt-2 bg-slate-100 rounded"><%= inspect(message.payload) %></p>
      </div>
    </div>
    <button class="bg-color:blue-200 rounded" phx-click="event">event</button>
    """
  end
end
