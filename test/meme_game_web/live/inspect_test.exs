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

  test "Page should render without a game, clicking in create game button should create a new game",
       %{conn: conn} do
    game_id = "abc123"
    conn = get(conn, "/game/#{game_id}/inspect")
    {:ok, view, _html} = live(conn)

    view
    |> element("#create_game")
    |> render_click()

    refute view |> element("#create_game") |> has_element?()
    assert view |> element("#kill_game") |> has_element?()
    assert view |> element("#info_game", game_id) |> has_element?()
    assert view |> element("#info_round", "1/4") |> has_element?()
    assert view |> element("#info_stage", "wait") |> has_element?()
    assert view |> element("#info_players", "1/4") |> has_element?()
  end

  test "should subscribe to game pubsub and render messages", %{conn: conn} do
    game = build(:game)
    conn = get(conn, "/game/#{game.id}/inspect")
    number_of_messages = 3

    {:ok, view, _html} = live(conn)

    view
    |> element("#create_game")
    |> render_click()

    for i <- 1..number_of_messages, do: MemeGame.PubSub.broadcast_game("message #{i}", game)

    assert view
           |> element("#messages_count", "[#{number_of_messages}] Messages:")
           |> has_element?()
  end
end
