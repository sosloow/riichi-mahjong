defmodule Mahjong.Hand do
  alias Mahjong.Hand
  alias Mahjong.Tile
  alias Mahjong.Wall
  alias Mahjong.Hand.Breakdown

  @type t :: %__MODULE__{}

  @max_tiles 14
  defstruct tiles: [], breakdown: %Breakdown{}

  @spec new() :: t()
  def new, do: %Hand{}

  @spec add_tile(t(), Tile.t()) :: {:ok, t()}
  def add_tile(%Hand{tiles: tiles} = hand, tile) when length(tiles) < @max_tiles do
    {:ok, %{hand | tiles: Tile.sort(tiles ++ [tile])}}
  end

  def add_tile(_hand, _tile), do: {:error, :hand_full}

  @spec deal(t(), Wall.t()) :: {:ok, {t(), Wall.t()}}
  def deal(%Hand{} = hand, wall) do
    with {:ok, {taken_tiles, updated_wall}} <- Wall.take(wall, @max_tiles) do
      {
        :ok,
        {
          %{hand | tiles: Tile.sort(taken_tiles)},
          updated_wall
        }
      }
    end
  end

  @spec discard(t(), integer()) :: {:ok, t()}
  def discard(%Hand{tiles: tiles} = hand, index) do
    {:ok, %{hand | tiles: List.delete_at(tiles, index)}}
  end

  @spec from_string_list(list(String.t())) :: t()
  def from_string_list(strings) do
    tiles =
      strings
      |> Enum.map(&Tile.from_string/1)
      |> Tile.sort()

    %Hand{tiles: tiles}
  end
end
