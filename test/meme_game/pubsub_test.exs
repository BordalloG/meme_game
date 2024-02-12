defmodule MemeGame.PubSubTest do
    use MemeGame.DataCase
    use ExUnit.Case, async: true
  
    import MemeGame.Factory

    setup do
        game = build(:game)
        {:ok, %{game: game}}
    end
 
    describe "game_topic/1" do
        test "should return a string containing game: + game id", %{game: game} do
            assert "game:" <> game.id == MemeGame.PubSub.game_topic(game)
        end        
    end

    describe "broadcast_game/2" do
        test "should broadcast a game as message to the given topic", %{game: game} do
            
            topic = MemeGame.PubSub.game_topic(game)
            event = "game_update"

            Phoenix.PubSub.subscribe(MemeGame.PubSub, topic)

            MemeGame.PubSub.broadcast_game(event, game)
            assert_receive %Phoenix.Socket.Broadcast{topic: ^topic, event: ^event, payload: ^game}
        end
    end
  end