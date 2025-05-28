defmodule Mahjong.Wall do
  alias Mahjong.Tile

  @type t :: %__MODULE__{}

  defstruct tiles: []

  @spec new() :: t()
  def new() do
    tiles =
      (numbered_tiles() ++ wind_tiles() ++ dragon_tiles())
      |> Enum.shuffle()

    %__MODULE__{tiles: tiles}
  end

  @spec numbered_tiles() :: [Tile.t()]
  defp numbered_tiles do
    for suit <- [:man, :pin, :sou],
        value <- 1..9,
        _ <- 1..4 do
      %Tile{suit: suit, value: value}
    end
  end

  @spec wind_tiles() :: [Tile.t()]
  defp wind_tiles do
    for wind <- [:east, :south, :west, :north],
        _ <- 1..4 do
      %Tile{suit: :wind, value: wind}
    end
  end

  @spec dragon_tiles() :: [Tile.t()]
  defp dragon_tiles do
    for dragon <- [:red, :green, :white],
        _ <- 1..4 do
      %Tile{suit: :dragon, value: dragon}
    end
  end

  @spec take(t(), integer()) :: {:ok, {[Tile.t()], t()}}
  def take(%__MODULE__{tiles: tiles} = wall, amount) do
    taken_tiles = Enum.take(tiles, amount)

    {:ok, {taken_tiles, %{wall | tiles: Enum.drop(tiles, amount)}}}
  end

  @spec take_tile(t()) :: {:ok, {Tile.t(), t()}}
  def take_tile(%__MODULE__{tiles: [tile | rest]}) do
    {:ok, {tile, %__MODULE__{tiles: rest}}}
  end

  def take_tile(%__MODULE__{tiles: []}) do
    {:error, :empty_wall}
  end
end
