defmodule MemeGameWeb.Accounts.PlayerHook do
  @moduledoc """
    Hook to assign player to socket when player in session or redirect to home page when it is not
  """

  def on_mount(:ensure_player_in_session, _params, %{"player" => player}, socket) do
    {:cont, Phoenix.Component.assign(socket, :player, player)}
  end

  def on_mount(:ensure_player_in_session, params, _session, socket) do
    game_id = params["game_id"]

    redirect_to =
      "/" <>
        if game_id do
          "?game_id=#{game_id}"
        else
          ""
        end

    socket =
      socket
      |> Phoenix.LiveView.redirect(to: redirect_to)
      |> Phoenix.LiveView.put_flash(:error, "You need to pick a nickname to join")

    {:halt, socket}
  end
end
