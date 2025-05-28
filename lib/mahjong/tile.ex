defmodule Mahjong.Tile do
  @type suit :: :man | :pin | :sou | :wind | :dragon
  @type rank :: 1..9
  @type honor :: :east | :south | :west | :north | :white | :green | :red
  @type t :: %__MODULE__{
          suit: suit,
          value: rank | honor
        }

  @enforce_keys [:suit, :value]
  defstruct [:suit, :value]

  @suit_order %{man: 0, pin: 1, sou: 2, wind: 3, dragon: 4}
  @honor_order %{east: 1, south: 2, west: 3, north: 4, white: 5, green: 6, red: 7}

  @spec sort_key(t()) :: {integer(), integer()}
  def sort_key(%__MODULE__{suit: suit, value: value}) do
    suit_rank = Map.fetch!(@suit_order, suit)

    value_rank =
      if is_integer(value),
        do: value,
        else: Map.fetch!(@honor_order, value)

    {suit_rank, value_rank}
  end

  @spec sort(list(t())) :: list(t())
  def sort(tiles) do
    Enum.sort_by(tiles, &sort_key/1)
  end

  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{suit: suit, value: value}) do
    case {suit, value} do
      {:man, n} when is_integer(n) -> "m#{n}"
      {:pin, n} when is_integer(n) -> "p#{n}"
      {:sou, n} when is_integer(n) -> "s#{n}"
      {:wind, :east} -> "we"
      {:wind, :south} -> "ws"
      {:wind, :west} -> "ww"
      {:wind, :north} -> "wn"
      {:dragon, :red} -> "dr"
      {:dragon, :green} -> "dg"
      {:dragon, :white} -> "dw"
      _ -> "unknown"
    end
  end

  @spec from_string(String.t()) :: t()
  def from_string(string) do
    {suit, value} =
      case string do
        <<"m", n>> when n in ~c"123456789" -> {:man, char_to_int(n)}
        <<"p", n>> when n in ~c"123456789" -> {:pin, char_to_int(n)}
        <<"s", n>> when n in ~c"123456789" -> {:sou, char_to_int(n)}
        "we" -> {:wind, :east}
        "ws" -> {:wind, :south}
        "ww" -> {:wind, :west}
        "wn" -> {:wind, :north}
        "dr" -> {:dragon, :red}
        "dg" -> {:dragon, :green}
        "dw" -> {:dragon, :white}
        _ -> {:man, 1}
      end

    %__MODULE__{suit: suit, value: value}
  end

  @spec char_to_int(char()) :: integer()
  defp char_to_int(char), do: char - ?0
end
