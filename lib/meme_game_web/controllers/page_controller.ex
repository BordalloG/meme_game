defmodule MemeGameWeb.PageController do
  alias MemeGame.Game.Player
  use MemeGameWeb, :controller

  def set_user(conn, nick) do
    put_session(conn, :player, %Player{id: UUID.uuid4(), nick: nick})
  end

  def start_session(conn, %{"nick" => nick, "game_id" => game_id} = _params) do
    if String.trim(game_id) == "" do
      start_session(conn, %{"nick" => nick})
    else
      set_user(conn, nick)
      |> redirect_to_game(game_id)
    end
  end

  def start_session(conn, %{"nick" => nick} = _params) do
    conn
    |> set_user(nick)
    |> redirect_to_new_game()
  end

  def redirect_to_new_game(conn) do
    game_id = Nanoid.generate()

    case MemeGame.GameServer.Supervisor.start_new_game_server(game_id, get_session(conn, :player)) do
      {:ok, _pid} -> conn |> redirect(to: "/game/#{game_id}")
      {:error, _reason} -> put_flash(conn, :error, "Something went wrong, try again later.")
    end
  end

  def redirect_to_game(conn, game_id) do
    conn |> redirect(to: "/game/#{game_id}")
  end
end
