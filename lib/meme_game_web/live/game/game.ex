defmodule MemeGameWeb.GameLive do
  use MemeGameWeb, :live_view

  def mount(params, session, socket) do
    {:ok, assign(socket, :session, session)}
  end

  def render(assigns) do
    ~H"""
    <%= inspect(assigns) %>
    """
  end
end
