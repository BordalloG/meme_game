defmodule MemeGame.Factory do
  @moduledoc """
    Factory porpuse is to allow you to include only a single module in all tests to have access to all factories
  """

  use ExMachina.Ecto, repo: MemeGame.Repo

  use MemeGame.CoordinateFactory
  use MemeGame.FieldFactory
  use MemeGame.GameFactory
  use MemeGame.PlayerFactory
  use MemeGame.MemeFactory
  use MemeGame.RoundFactory
  use MemeGame.SettingsFactory
  use MemeGame.VoteFactory
end
