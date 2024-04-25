defmodule MemeGame.Game do
  @moduledoc """
      Representation of a Game, as well as it's validations and stages
  """
  import MemeGameWeb.Gettext

  require Logger

  alias MemeGame.Game
  alias MemeGame.Game.{Meme, Player, Round, Settings}

  use Machinery,
    field: :stage,
    states: ["wait", "design", "vote", "round_summary", "scoreboard", "end"],
    transitions: %{
      "wait" => "design",
      "design" => "vote",
      "vote" => "round_summary",
      "round_summary" => "scoreboard",
      "scoreboard" => ["wait", "end"]
    }

  @type t :: %__MODULE__{
          id: String.t(),
          owner: Player.t(),
          stage: String.t(),
          players: [Player.t()],
          settings: Settings.t(),
          current_round: integer(),
          rounds: [Round.t()]
        }

  defstruct [
    :id,
    :owner,
    stage: "wait",
    players: [],
    settings: %Settings{},
    current_round: 1,
    rounds: []
  ]

  require Machinery

  @dialyzer {:no_return, [transition_to: 2, next_stage: 1]}

  @spec current_round(Game.t()) :: Round.t() | nil
  def current_round(%Game{} = game) do
    Enum.find(game.rounds, fn round -> round.number == game.current_round end)
  end

  @spec transition_to(Game.t(), String.t()) :: {:ok, Game.t()} | {:error, String.t()}
  def transition_to(%Game{} = game, stage) do
    Logger.info("Game id #{game.id} transitioning from #{game.stage} to #{stage}")

    Machinery.transition_to(game, __MODULE__, stage)
  end

  @spec next_stage(Game.t()) :: {:ok, Game.t()} | {:error, String.t()}
  def next_stage(%Game{stage: "wait"} = game) do
    case can_start_game?(game) do
      {:ok, game} ->
        create_new_round(game)
        |> transition_to("design")

      {:error, reason} ->
        {:error, reason}
    end
  end

  def next_stage(%Game{stage: "design"} = game) do
    transition_to(game, "vote")
  end

  def next_stage(%Game{stage: "vote"} = game) do
    transition_to(game, "round_summary")
  end

  def next_stage(%Game{stage: "round_summary"} = game) do
    Game.calculate_and_update_current_round_score(game)
    |> transition_to("scoreboard")
  end

  def next_stage(%Game{stage: "scoreboard"} = game) do
    if game.current_round == game.settings.rounds do
      transition_to(game, "end")
    else
      game = %{game | current_round: game.current_round + 1}
      transition_to(game, "wait")
    end
  end

  @spec can_start_game?(Game.t()) :: {:ok, Game.t()} | {:error, String.t()}
  defp can_start_game?(%Game{} = game) do
    if length(game.players) >= 2 do
      {:ok, game}
    else
      {:error, dgettext("errors", "At least two players are necessary to start the game.")}
    end
  end

  @spec can_join?(Game.t(), Player.t()) :: {:ok, Game.t()} | {:error, [String.t()]}
  def can_join?(%Game{} = game, player) do
    validations = [
      game_full?(game),
      player_has_valid_nick?(player),
      nick_available?(game, player)
    ]

    errors = for {:error, reason} <- validations, do: reason

    if Enum.any?(errors) do
      {:error, errors}
    else
      {:ok, game}
    end
  end

  @spec player_in_game?(Player.t(), Game.t()) :: boolean()
  def player_in_game?(player, game) do
    Enum.any?(game.players, fn p -> p == player end)
  end

  @spec game_full?(Game.t()) :: {:ok, Game.t()} | {:error, String.t()}
  defp game_full?(%Game{} = game) do
    if length(game.players) >= game.settings.max_players do
      {:error, dgettext("errors", "Game is already full")}
    else
      {:ok, game}
    end
  end

  @spec player_has_valid_nick?(Player.t()) :: {:ok, Player.t()} | {:error, String.t()}
  defp player_has_valid_nick?(player) do
    if String.trim(player.nick) == "" do
      {:error, dgettext("errors", "Empty nicks are not allowed")}
    else
      {:ok, player}
    end
  end

  @spec nick_available?(Game.t(), Player.t()) :: {:ok, Game.t()} | {:error, String.t()}
  defp nick_available?(%Game{} = game, player) do
    if Enum.any?(game.players, fn p -> p.nick == player.nick end) do
      {:error, dgettext("errors", "This nick is already in use")}
    else
      {:ok, game}
    end
  end

  @spec calculate_meme_score(Game.t(), Meme.t()) :: integer()
  def calculate_meme_score(game, meme) do
    Enum.reduce(meme.votes, 0, fn vote, acc ->
      value =
        case vote.value do
          :upvote -> game.settings.score.upvote
          :downvote -> game.settings.score.downvote
          :midvote -> game.settings.score.midvote
        end

      acc + value
    end)
  end

  def calculate_and_update_current_round_score(%Game{} = game) do
    round = Game.current_round(game)

    scored_memes =
      Enum.map(round.memes, fn meme ->
        score = calculate_meme_score(game, meme)
        Meme.update_score(meme, score)
      end)

    players =
      Enum.reduce(scored_memes, game.players, fn meme, players ->
        owner = meme.owner

        Enum.map(players, fn
          ^owner -> %{owner | score: owner.score + meme.score}
          player -> player
        end)
      end)

    %{game | players: players}
    |> Game.update_current_round(%{round | memes: scored_memes})
  end

  @spec create_new_round(Game.t()) :: Game.t()
  def create_new_round(%Game{} = game) do
    %{game | rounds: [%Round{number: game.current_round} | game.rounds]}
  end

  @spec update_current_round(Game.t(), Round.t()) :: Game.t()
  def update_current_round(game, updated_current_round) do
    %{
      game
      | rounds:
          Enum.map(game.rounds, fn round ->
            if round.number == updated_current_round.number do
              updated_current_round
            else
              round
            end
          end)
    }
  end
end
