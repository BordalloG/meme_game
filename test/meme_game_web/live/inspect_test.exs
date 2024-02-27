defmodule MemeGameWeb.InspectTest do
  use MemeGame.DataCase
  use ExUnit.Case, async: true

  import MemeGame.Factory
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint MemeGameWeb.Endpoint

  setup do
    conn = build_conn()
    {:ok, %{conn: conn}}
  end

  test "page should load and render game id", %{conn: conn} do
    game_id = "abc123"
    conn = get(conn, "/game/#{game_id}/inspect")

    assert html_response(conn, 200) =~ "Inspecting Game #{game_id}"
  end

  test "should subscribe to game pubsub and render messages", %{conn: conn} do
    game = build(:game)
    conn = get(conn, "/game/#{game.id}/inspect")
    number_of_messages = 3

    {:ok, view, _html} = live(conn)
    for i <- 1..number_of_messages, do: MemeGame.PubSub.broadcast_game(i, game)

    assert view
           |> element("#messages_count", "[#{number_of_messages}] Messages:")
           |> has_element?()
  end
end
