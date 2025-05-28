defmodule Mahjong.Hand.Breakdown do
  alias Mahjong.Hand
  alias Mahjong.Tile

  @type t :: %__MODULE__{}

  defstruct combos: [], best_combo: nil

  @spec breakdown_hand(Hand.t()) :: Hand.t()
  def breakdown_hand(%Hand{tiles: tiles} = hand) do
    combos =
      tiles
      |> Enum.group_by(& &1.suit)
      |> Enum.map(&combine_by_suit/1)
      |> Enum.filter(&(!Enum.empty?(&1)))
      |> Enum.reduce([[]], fn suit_combo_variants, acc ->
        for combo <- acc, variant <- suit_combo_variants do
          combo ++ variant
        end
      end)
      |> Enum.map(fn combo ->
        calc_stats(combo)
        |> Map.merge(%{
          sets: combo
        })
      end)

    best_combo =
      Enum.max_by(combos, fn %{counts: counts} ->
        counts.triplet * 10 + counts.pair
      end)

    %{
      hand
      | breakdown: %__MODULE__{
          combos: combos,
          best_combo: best_combo
        }
    }
  end

  @spec combine_by_suit({atom(), list(Tile.t())}) :: list(list())
  defp combine_by_suit({suit, tiles}) do
    tiles
    |> Enum.map(& &1.value)
    |> Enum.frequencies()
    |> do_combine_by_suit(suit, [], 1)
    |> prune_subsets()
  end

  @spec do_combine_by_suit(map(), atom(), list(), integer()) :: list(list())
  defp do_combine_by_suit(freqs, suit, acc, min_rank) do
    sets =
      case suit do
        s when s in [:man, :pin, :sou] -> find_suit_sets(freqs, min_rank)
        _ -> find_honor_sets(freqs, min_rank)
      end

    if Enum.empty?(sets) do
      [acc |> Enum.map(fn {kind, rank} -> {kind, suit, rank} end)]
    else
      for set <- sets,
          reduced = subtract_set(freqs, set),
          combo <-
            do_combine_by_suit(
              reduced,
              suit,
              [set | acc],
              elem(set, 1)
            ) do
        combo
      end
    end
  end

  @spec subtract_set(map(), tuple()) :: map()
  defp subtract_set(freqs, {:pon, rank}) do
    freqs |> Map.update!(rank, &(&1 - 3))
  end

  defp subtract_set(freqs, {:pair, rank}) do
    freqs |> Map.update!(rank, &(&1 - 2))
  end

  defp subtract_set(freqs, {:chi, rank}) do
    freqs
    |> Map.update!(rank, &(&1 - 1))
    |> Map.update!(rank + 1, &(&1 - 1))
    |> Map.update!(rank + 2, &(&1 - 1))
  end

  @spec find_chis(map(), integer()) :: list(tuple())
  defp find_chis(freqs, min_rank) do
    for rank <- max(min_rank, 1)..7,
        Map.get(freqs, rank, 0) > 0,
        Map.get(freqs, rank + 1, 0) > 0,
        Map.get(freqs, rank + 2, 0) > 0 do
      {:chi, rank}
    end
  end

  @spec find_pons(map(), integer()) :: list(tuple())
  defp find_pons(freqs, min_rank) do
    freqs
    |> Enum.filter(fn {rank, count} ->
      rank >= min_rank and count >= 3
    end)
    |> Enum.map(fn {rank, _} ->
      {
        :pon,
        rank
      }
    end)
  end

  @spec find_pairs(map(), integer()) :: list(tuple())
  defp find_pairs(freqs, min_rank) do
    freqs
    |> Enum.filter(fn {rank, count} ->
      rank >= min_rank and count >= 2
    end)
    |> Enum.map(fn {rank, _} ->
      {
        :pair,
        rank
      }
    end)
  end

  @spec find_honor_sets(map(), integer()) :: list(tuple())
  defp find_honor_sets(freqs, min_rank) do
    find_pons(freqs, min_rank) ++ find_pairs(freqs, min_rank)
  end

  @spec find_suit_sets(map(), integer()) :: list(tuple())
  defp find_suit_sets(freqs, min_rank) do
    find_chis(freqs, min_rank) ++ find_pons(freqs, min_rank) ++ find_pairs(freqs, min_rank)
  end

  @spec prune_subsets(list(list())) :: list()
  defp prune_subsets(combos) do
    sets = Enum.map(combos, &MapSet.new/1)

    enumsets = Enum.zip(combos, sets)

    enumsets
    |> Enum.filter(fn {_combo, set} ->
      not Enum.any?(sets, fn other_set ->
        MapSet.subset?(set, other_set) and other_set != set
      end)
    end)
    |> Enum.map(&elem(&1, 0))
  end

  @spec calc_stats(list(tuple())) :: map()
  defp calc_stats(combo) do
    counts =
      combo
      |> Enum.group_by(&elem(&1, 0))
      |> Map.merge(%{pon: [], chi: [], pair: []}, fn _key, v1, v2 ->
        v1 || v2
      end)

    %{
      counts: %{
        pon: length(counts.pon),
        chi: length(counts.chi),
        triplet: length(counts.pon) + length(counts.chi),
        pair: length(counts.pair)
      }
    }
  end
end
