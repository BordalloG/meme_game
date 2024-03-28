defmodule MemeGameWeb.PageController do
  alias MemeGame.Game.Player
  use MemeGameWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def start_session(conn, %{"nick" => nick, "action" => action} = params) do
    action =
      cond do
        action == "Existing Game" -> :existing_game
        action == "New Game" -> :new_game
      end

    conn
    |> put_session(:player, %Player{id: UUID.uuid4(), nick: nick})
    |> redirect_to_game(action)
  end

  def redirect_to_game(conn, :new_game) do
    conn |> redirect(to: "/game")
  end

  def redirect_to_game(conn, :existing_game) do
    conn |> redirect(to: "/game")
  end
end
