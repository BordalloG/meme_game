defmodule MemeGameWeb.PageController do
  alias MemeGame.Game.Player
  use MemeGameWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def start_session(conn, %{"nick" => nick, "action" => action} = _params) do
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
    game_id = Nanoid.generate()
    case MemeGame.GameServer.Supervisor.start_new_game_server(game_id, get_session(conn, :player)) do
      {:ok, _pid} -> conn |> redirect(to: "/game/#{game_id}")
      {:error, _reason} -> put_flash(conn,:error, "Something went wrong, try again later.")
    end
  end

  def redirect_to_game(conn, :existing_game) do
    conn |> redirect(to: "/game/321")
  end
end
