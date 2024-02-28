defmodule MemeGame.Game do
  @moduledoc """
      Representation of a Game, as well as it's validations and stages
  """
  import MemeGameWeb.Gettext

  require Logger

  alias MemeGame.Game
  alias MemeGame.Game.{Player, Settings}

  use Machinery,
    field: :stage,
    states: ["wait", "design", "vote", "round_summary", "score_board", "end"],
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
          settings: Settings.t()
        }

  defstruct [:id, :owner, stage: "wait", players: [], settings: %Settings{}]

  require Machinery

  @dialyzer {:no_return, [transition_to: 2, next_stage: 1]}

  @spec transition_to(Game.t(), String.t()) :: {:ok, Game.t()} | {:error, String.t()}
  def transition_to(game, stage) do
    Logger.info("Game id #{game.id} transitioning from #{game.stage} to #{stage}")

    Machinery.transition_to(game, __MODULE__, stage)
  end

  @spec next_stage(Game.t()) :: {:ok, Game.t()} | {:error, String.t()}
  def next_stage(%Game{stage: "wait"} = game) do
    case can_start_game?(game) do
      {:ok, game} -> transition_to(game, "design")
      {:error, reason} -> {:error, reason}
    end
  end

  def next_stage(%Game{stage: "design"} = game) do
    transition_to(game, "vote")
  end

  def next_stage(%Game{stage: "vote"} = game) do
    transition_to(game, "round_summary")
  end

  def next_stage(%Game{stage: "round_summary"} = game) do
    transition_to(game, "scoreboard")
  end

  def next_stage(%Game{stage: "scoreboard"} = game) do
    transition_to(game, "wait")
  end

  @spec can_start_game?(Game.t()) :: {:ok, Game.t()} | {:error, String.t()}
  defp can_start_game?(game) do
    if length(game.players) >= 2 do
      {:ok, game}
    else
      {:error, dgettext("errors", "At least two players are necessary to start the game.")}
    end
  end

  @spec can_join?(Game.t(), Player.t()) :: {:ok, Game.t()} | {:error, [String.t()]}
  def can_join?(game, player) do
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

  @spec game_full?(Game.t()) :: {:ok, Game.t()} | {:error, String.t()}
  defp game_full?(game) do
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
  defp nick_available?(game, player) do
    if Enum.any?(game.players, fn p -> p.nick == player.nick end) do
      {:error, dgettext("errors", "This nick is already in use")}
    else
      {:ok, game}
    end
  end
end
