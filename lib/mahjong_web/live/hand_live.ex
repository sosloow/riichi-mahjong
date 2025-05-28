defmodule MahjongWeb.HandLive do
  use MahjongWeb, :live_view

  # alias Mahjong.Hand
  # alias Mahjong.Wall
  alias Mahjong.Game

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:game, Game.new())}
  end

  def handle_event("reset", _, socket) do
    {:noreply,
     socket
     |> assign(:game, Game.new())}
  end

  def handle_event("deal", _, socket) do
    with {:ok, updated_game} <- Game.deal(socket.assigns.game) do
      {:noreply,
       socket
       |> assign(:game, updated_game)}
    else
      {:error, :empty_wall} ->
        {:noreply, put_flash(socket, :error, "Empty wall")}
    end
  end

  def handle_event("discard_tile", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)

    with {:ok, updated_game} <- Game.discard_and_take(socket.assigns.game, idx) do
      {:noreply,
       socket
       |> assign(game: updated_game)}
    else
      {:error, :empty_wall} ->
        {:noreply, put_flash(socket, :error, "Out of tiles")}
    end
  end
end
