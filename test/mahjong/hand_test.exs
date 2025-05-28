defmodule Mahjong.HandTest do
  use ExUnit.Case
  alias Mahjong.Hand
  alias Mahjong.Tile

  describe "Mahjong.Hand.from_string_list/1" do
    test "converts string list to Hand" do
      hand = Hand.from_string_list(~w[m1 m2 m2 m3 m3 m4 m6 m7 m8 p2 p3 p4 p5 p5])

      assert length(hand.tiles) == 14

      [first_tile | _rest] = hand.tiles

      assert %Tile{suit: :man, value: 1} = first_tile
    end
  end
end
