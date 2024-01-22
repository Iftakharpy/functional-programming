defmodule BlackjackDeck do
  @ranks ~w(2 3 4 5 6 7 8 9 10 Jack Queen King Ace)s
  @suits ~w(Hearts Diamonds Clubs Spades)s

  def get_deck() do
    for rank <- @ranks, suit <- @suits, do: {rank, suit}
  end

  def get_shuffled_deck() do
    get_deck() |> Enum.shuffle()
  end
end


defmodule Player do
  def start() do
    spawn(__MODULE__, fn state -> loop(state) end, [])
  end

  def loop(state) do
    receive do

    end
  end
end

defmodule Dealer do
  def start() do
    spawn(__MODULE__, fn state -> loop(state) end, [])
  end

  def loop(state) do
    receive do

    end
  end
end


defmodule Blackjack do
  def start() do
    spawn(__MODULE__, fn state -> loop(state) end, %{

    })
  end

  def loop(state) do
    receive do

    end
  end
end


IO.inspect(BlackjackDeck.get_shuffled_deck())
