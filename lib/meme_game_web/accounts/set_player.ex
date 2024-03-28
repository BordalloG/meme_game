defmodule MemeGameWeb.Accounts.SetPlayer do
  @moduledoc """
    Plugs player struct into socket when the player info is in the session, or redirect to home when isn't
  """
  import Plug.Conn

  def init(_options) do
  end

  def call(conn, _options) do
    if conn.assigns[:player] do
      conn
    else
      player = get_session(conn, :player)

      if player == nil do
        conn
        |> Phoenix.Controller.redirect(to: "/")
      else
        assign(conn, :player, player)
      end
    end
  end
end
