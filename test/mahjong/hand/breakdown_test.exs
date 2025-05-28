defmodule Mahjong.Hand.BreakdownTest do
  use ExUnit.Case
  import Mahjong.Hand.Breakdown
  alias Mahjong.Hand
  # alias Mahjong.Tile
  alias Mahjong.Hand.Breakdown

  describe "breakdown_hand/1" do
    test "Detects pons, chis and pairs" do
      hand = Hand.from_string_list(~w[m2 m2 m2 m3 m3 m3 m6 m7 m8 p2 p3 p4 p5 p5])

      assert %Hand{breakdown: %Breakdown{best_combo: best_combo}} =
               breakdown_hand(hand)

      assert best_combo.counts.triplet == 4
    end

    test "Detects pons of honors" do
      hand = Hand.from_string_list(~w[m2 m2 m2 m3 m3 m3 m5 m6 m7 dw dw dw ww ww])

      assert %Hand{breakdown: %Breakdown{best_combo: best_combo}} =
               breakdown_hand(hand)

      assert best_combo.counts.triplet == 4
      assert best_combo.counts.pair == 1

      pairs = best_combo.sets |> Enum.filter(&(elem(&1, 0) == :pair))
      assert pairs == [{:pair, :wind, :west}]
    end

    test "detects combos of overlapping chis" do
      hand = Hand.from_string_list(~w[m2 m3 m4 m5 m6 m9 s6 s7 s8 p2 p3 p4 p5 p5])

      assert %Hand{breakdown: %Breakdown{combos: combos}} =
               breakdown_hand(hand)

      assert Enum.find(combos, fn %{sets: sets} ->
               Enum.find(sets, fn
                 {:chi, :man, 2} -> true
                 _ -> false
               end)
             end)

      assert Enum.find(combos, fn %{sets: sets} ->
               Enum.find(sets, fn
                 {:chi, :man, 3} -> true
                 _ -> false
               end)
             end)

      assert Enum.find(combos, fn %{sets: sets} ->
               Enum.find(sets, fn
                 {:chi, :man, 4} -> true
                 _ -> false
               end)
             end)
    end
  end
end
