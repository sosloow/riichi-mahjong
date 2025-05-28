defmodule Mahjong.Game do
  alias Mahjong.Game
  alias Mahjong.Wall
  alias Mahjong.Hand

  defstruct [:wall, :hand]

  @type t :: %__MODULE__{}

  @spec new() :: t()
  def new() do
    init = %Game{wall: Wall.new(), hand: Hand.new()}

    with {:ok, game} <- Game.deal(init) do
      game
    end
  end

  @spec deal(t()) :: {:ok, t()}
  def deal(%Game{wall: wall, hand: hand} = game) do
    with {:ok, {updated_hand, updated_wall}} <- Hand.deal(hand, wall) do
      {:ok, %{game | wall: updated_wall, hand: updated_hand}}
    end
  end

  @spec discard_and_take(t(), integer()) :: {:ok, t()}
  def discard_and_take(%Game{wall: wall, hand: hand} = game, idx) do
    with {:ok, updated_hand} <- Hand.discard(hand, idx),
         {:ok, {tile, updated_wall}} <- Wall.take_tile(wall),
         {:ok, updated_hand} <- Hand.add_tile(updated_hand, tile) do
      {:ok, %{game | wall: updated_wall, hand: updated_hand}}
    end
  end
end
