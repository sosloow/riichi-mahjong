defmodule Mahjong.Hand.Breakdown do
  alias Mahjong.Hand
  alias Mahjong.Tile

  @type t :: %__MODULE__{}

  defstruct combos: [], waits: nil, best_combo: nil

  @spec breakdown_hand(Hand.t()) :: Hand.t()
  def breakdown_hand(%Hand{tiles: tiles} = hand) do
    combos =
      tiles
      |> Enum.group_by(& &1.suit)
      |> Enum.map(&combine_by_suit/1)
      |> Enum.filter(&(!Enum.empty?(&1)))
      |> Enum.reduce([%{sets: [], waits: []}], fn suit_combo_variants, acc ->
        for combo <- acc, variant <- suit_combo_variants do
          merge_combos(combo, variant)
        end
      end)
      |> Enum.map(fn combo ->
        has_pair = Enum.any?(combo.waits, fn {kind, _, _} -> kind == :pair end)

        clean_waits =
          if has_pair do
            Enum.filter(combo.waits, fn {kind, _, _} -> kind != :pair end)
          else
            combo.waits
          end
          |> MapSet.new()

        calc_stats(combo.sets)
        |> Map.merge(%{
          sets: combo.sets,
          waits: clean_waits
        })
      end)

    best_combo = Enum.max_by(combos, & &1.strength)

    %{
      hand
      | breakdown: %__MODULE__{
          combos: combos,
          best_combo: best_combo,
          waits:
            Enum.reduce(combos, MapSet.new(), fn combo, acc -> MapSet.union(combo.waits, acc) end)
        }
    }
  end

  @spec combine_by_suit({atom(), list(Tile.t())}) :: list()
  defp combine_by_suit({suit, tiles}) do
    freqs =
      tiles
      |> Enum.map(& &1.value)
      |> Enum.frequencies()

    next_sets_fun =
      case suit do
        s when s in [:man, :pin, :sou] -> &find_suit_sets/2
        _ -> &find_honor_sets/2
      end

    do_combine(freqs, [], 1, next_sets_fun)
    |> prune_subsets()
    |> Enum.map(fn sets ->
      restFreqs = Enum.reduce(sets, freqs, fn set, acc -> subtract_set(acc, set) end)

      %{
        suit: suit,
        sets: Enum.map(sets, fn {kind, rank} -> {kind, suit, rank} end),
        restFreqs: restFreqs,
        waits:
          find_waits(restFreqs, sets)
          |> Enum.map(fn {kind, rank} -> {kind, suit, rank} end)
      }
    end)
  end

  @spec do_combine(map(), list(), integer(), function()) :: list(list())
  defp do_combine(freqs, acc, min_rank, next_sets_fun) do
    sets = next_sets_fun.(freqs, min_rank)

    if Enum.empty?(sets) do
      [acc]
    else
      for set <- sets,
          reduced = subtract_set(freqs, set),
          combo <-
            do_combine(
              reduced,
              [set | acc],
              elem(set, 1),
              next_sets_fun
            ) do
        combo
      end
    end
  end

  defp find_waits(rest_freqs, sets) do
    pairs = sets |> Enum.filter(fn {kind, _} -> kind == :pair end)
    pon_waits = pairs |> Enum.map(fn {:pair, rank} -> {:pon, rank} end)
    chi_waits = find_chi_waits(rest_freqs)

    pair_waits =
      rest_freqs
      |> Enum.filter(fn {_rank, count} -> count == 1 end)
      |> Enum.map(fn {rank, _count} -> {:pair, rank} end)

    pon_waits ++ chi_waits ++ pair_waits
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

  defp find_suit_sets(freqs, min_rank) do
    find_chis(freqs, min_rank) ++ find_pons(freqs, min_rank) ++ find_pairs(freqs, min_rank)
  end

  defp find_honor_sets(freqs, min_rank) do
    find_pons(freqs, min_rank) ++ find_pairs(freqs, min_rank)
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
      |> then(fn sets ->
        %{
          pon: length(sets.pon),
          chi: length(sets.chi),
          triplet: length(sets.pon) + length(sets.chi),
          pair: length(sets.pair)
        }
      end)

    has_pair = counts.pair > 0

    shanten =
      min(
        4 - counts.triplet - if(has_pair, do: 1, else: 0),
        6 - counts.pair
      )

    %{
      counts: counts,
      shanten: shanten,
      tenpai?: shanten <= 0,
      complete?: shanten == -1,
      strength: counts.triplet * 10 + counts.pair
    }
  end

  defp merge_combos(
         %{sets: sets1, waits: waits1},
         %{sets: sets2, waits: waits2}
       ) do
    %{
      sets: sets1 ++ sets2,
      waits: waits1 ++ waits2
    }
  end

  defp find_chi_waits(freqs) do
    for rank <- 1..9,
        (Map.get(freqs, rank - 2, 0) > 0 and Map.get(freqs, rank - 1, 0) > 0) or
          (Map.get(freqs, rank - 1, 0) > 0 and Map.get(freqs, rank + 1, 0) > 0) or
          (Map.get(freqs, rank + 1, 0) > 0 and Map.get(freqs, rank + 2, 0) > 0) do
      {:chi, rank}
    end
  end
end
