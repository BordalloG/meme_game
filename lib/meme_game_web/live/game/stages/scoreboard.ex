defmodule MemeGameWeb.Game.Stages.ScoreboardComponent do
  use MemeGameWeb, :live_component
  def render(assigns) do
    ~H"""
      <div> scoreboard </div>
    """
  end
end
