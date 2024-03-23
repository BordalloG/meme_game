defmodule MemeGame.GameFactory do
  @moduledoc """
    Defines the factory for MemeGame.Game
  """
  defmacro __using__(_opts) do
    quote do
      def game_factory do
        owner = build(:player)

        %MemeGame.Game{
          id: Faker.UUID.v4(),
          owner: owner,
          stage: "wait",
          players: build_list(2, :player) ++ [owner],
          settings: build(:settings),
          current_round: 1,
          rounds: []
        }
      end

      def ongoing_game_factory(attrs) do
        owner = build(:player)
        owner_vote = build(:vote, %{player: owner})

        player2 = build(:player, %{nick: "Loren"})
        player2_vote = build(:vote, %{player: player2})

        player3 = build(:player, %{nick: "Mario"})
        player3_vote = build(:vote, %{player: player2})

        player4 = build(:player, %{nick: "Lucy"})
        player4_vote = build(:vote, %{player: player2})

        owner_meme =
          build(:meme, %{owner: owner, votes: [player2_vote, player3_vote, player4_vote]})

        player2_meme =
          build(:meme, %{owner: player2, votes: [owner_vote, player3_vote, player4_vote]})

        player3_meme =
          build(:meme, %{owner: player3, votes: [owner_vote, player2_vote, player4_vote]})

        player4_meme =
          build(:meme, %{owner: player4, votes: [owner_vote, player2_vote, player3_vote]})

        round =
          build(:round, %{
            number: 1,
            memes: [owner_meme, player2_meme, player3_meme, player4_meme]
          })

        %MemeGame.Game{
          id: Faker.UUID.v4(),
          owner: owner,
          stage: "summary",
          players: [owner, player2, player3, player4],
          settings: build(:settings),
          current_round: 1,
          rounds: [round]
        }
      end
    end
  end
end
