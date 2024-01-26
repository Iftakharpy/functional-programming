defmodule Card do
  @enforce_keys [:rank, :suit]
  defstruct rank: nil, suit: nil
end

defmodule BlackjackDeck do
  @suits ["Spades", "Hearts", "Clubs", "Diamonds"]
  @ranks ["Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King"]

  @spec new_deck() :: list[Card.t()]
  def new_deck() do
    for rank <- @ranks, suit <- @suits do
      %Card{rank: rank, suit: suit}
    end
  end

  @spec shuffle(list[Card.t()]) :: list[Card.t()]
  def shuffle(deck) when is_list(deck) do
    Enum.shuffle(deck)
  end

  def get_shuffled_deck() do
    new_deck() |> shuffle()
  end
end

defmodule Dealer do
  @type state :: %{
          dealer_hand: list[Card.t()],
          player_hand: list[Card.t()],
          current_shoe: list[Card.t()],
          dealers_turn?: boolean()
        }
  def start_loop() do
    dealer_pid = spawn_link(&loop/0)
    Process.register(dealer_pid, :dealer_process)
    dealer_pid
  end

  def stop_loop() do
    send(:dealer_process, {:stop_loop})
    Process.unregister(:dealer_process)
  end

  def initial_game_state() do
    current_shoe = BlackjackDeck.get_shuffled_deck()
    {initial_dealer_hand, rest} = current_shoe |> Enum.split(2)
    {initial_player_hand, remaining_cards} = rest |> Enum.split(2)

    %{
      dealer_hand: initial_dealer_hand,
      player_hand: initial_player_hand,
      current_shoe: remaining_cards,
      dealers_turn?: false
    }
  end

  def loop() do
    loop(initial_game_state())
  end

  @spec loop(state()) :: nil
  def loop(state) do
    player_score = calculate_score(state.player_hand)

    state =
      cond do
        state.dealers_turn? and should_dealer_hit?(state.dealer_hand) ->
          send(:dealer_process, {:deal_card, :to_dealer})
          state

        not state.dealers_turn? and not (player_score > 21) ->
          send(:player_process, {:player_turn})
          state

        not state.dealers_turn? and player_score > 21 ->
          %{state | dealers_turn?: true}

        true ->
          state
      end

    new_state =
      receive do
        {:player_stand} ->
          %{state | dealers_turn?: true}

        {:deal_card, :to_player} ->
          [top_card | rest] = state.current_shoe
          %{state | current_shoe: rest, player_hand: [top_card | state.player_hand]}

        {:deal_card, :to_dealer} ->
          [top_card | rest] = state.current_shoe
          %{state | current_shoe: rest, dealer_hand: [top_card | state.dealer_hand]}

        {:stop_loop} ->
          nil

        {:show_hands, to_process} ->
          IO.puts("")
          IO.puts("Dealer's #{hand_to_string(state.dealer_hand)}")
          IO.puts("Player's #{hand_to_string(state.player_hand)}")
          IO.puts("")
          send(to_process, {:hands_shown})
          state
      end

    case new_state do
      nil ->
        :ok

      _ ->
        case game_result(new_state.dealer_hand, new_state.player_hand) do
          {:game_continues, :dealer_must_hit} ->
            loop(new_state)

          {:game_ends, result} ->
            if new_state.dealers_turn? do
              IO.puts("")
              IO.puts("------------ Game result ------------")
              IO.puts("Dealer's #{hand_to_string(new_state.dealer_hand)}")
              IO.puts("Player's #{hand_to_string(new_state.player_hand)}")
              IO.puts("")

              case result do
                :tie ->
                  IO.puts("It's a tie!")

                :dealer_busts ->
                  IO.puts("Dealer busts, player wins!")

                :player_busts ->
                  IO.puts("Player busts, dealer wins!")

                :player_wins ->
                  IO.puts("Player wins!")

                :dealer_wins ->
                  IO.puts("Dealer wins!")
              end

              IO.puts("------------ Game ended ------------")
              IO.puts("")

              play_again? = true
              #   IO.gets("Do you want to play again? (y/n): ")
              # |> String.trim()
              # |> String.downcase()
              # |> String.starts_with?("y")

              if play_again? do
                IO.puts("====================================")
                IO.puts("Starting new game...")
                send(:dealer_process, {:show_hands, :player_process})
                loop(initial_game_state())
              end
            else
              loop(new_state)
            end
        end
    end
  end

  defp hand_to_string(hand) do
    "Score: #{calculate_score(hand)}, Hand: #{Enum.map(hand, &"#{&1.rank} of #{&1.suit}") |> Enum.join(", ")}"
  end

  def should_dealer_hit?(dealer_hand) do
    calculate_score(dealer_hand) < 17
  end

  def game_result(dealer_hand, player_hand) do
    player_score = calculate_score(player_hand)
    dealer_score = calculate_score(dealer_hand)

    cond do
      # Check for bust
      player_score > 21 -> {:game_ends, :player_busts}
      dealer_score > 21 -> {:game_ends, :dealer_busts}
      # Dealer must hit until score is 17 or higher
      should_dealer_hit?(dealer_hand) -> {:game_continues, :dealer_must_hit}
      # When scores are equal it's a tie and score must not exceed 21
      player_score == dealer_score and player_score <= 21 -> {:game_ends, :tie}
      # When player has 21 or higher score than dealer, player wins
      player_score == 21 or player_score > dealer_score -> {:game_ends, :player_wins}
      # At this point dealer has higher score than player and dealer wins
      true -> {:game_ends, :dealer_wins}
    end
  end

  @score_map %{
    # Ace can be 1 or 11, the score will be in player's favor
    "Ace" => 11,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "5" => 5,
    "6" => 6,
    "7" => 7,
    "8" => 8,
    "9" => 9,
    "10" => 10,
    "Jack" => 10,
    "Queen" => 10,
    "King" => 10
  }
  @spec has_ace?(list[Card.t()]) :: boolean()
  def has_ace?(hand) do
    Enum.any?(hand, fn card -> card.rank == "Ace" end)
  end

  @spec calculate_score(list[Card.t()]) :: integer()
  def calculate_score(hand) do
    score =
      hand
      |> Enum.map(& &1.rank)
      |> Enum.map(&@score_map[&1])
      |> Enum.sum()

    if score > 21 and has_ace?(hand) do
      # Since an ace can be 1 or 11,
      # we can subtract 10 to get the lower score(1) to avoid busting
      score - 10
    else
      score
    end
  end
end

defmodule Player do
  def start_loop() do
    player_pid = spawn_link(&loop/0)
    Process.register(player_pid, :player_process)
    player_pid
  end

  def stop_loop() do
    send(:player_process, {:stop_loop})
    Process.unregister(:player_process)
  end

  def loop() do
    receive do
      {:player_turn} ->
        send(:dealer_process, {:show_hands, :player_process})
        receive do
          {:hands_shown} -> :timer.sleep(20)
        end

        player_choice = IO.gets("Hit or stand? (h/s): ") |> String.trim() |> String.downcase()

        case player_choice do
          "h" ->
            send(:dealer_process, {:deal_card, :to_player})

          "s" ->
            send(:dealer_process, {:player_stand})

          _ ->
            IO.puts("Invalid choice, try again.")
            send(:player_process, {:player_turn})
        end

        loop()

      {:stop_loop} ->
        :ok
    end
  end
end

defmodule BlackjackGame do
  def start_game() do
    IO.puts("Starting Blackjack game...")
    IO.puts("")

    player_pid = Player.start_loop()
    dealer_pid = Dealer.start_loop()

    # Wait for processes to finish
    loop_while(fn -> Process.alive?(player_pid) and Process.alive?(dealer_pid) end)

    cond do
      Process.alive?(player_pid) -> Player.stop_loop()
      Process.alive?(dealer_pid) -> Dealer.stop_loop()
    end
  end

  defp loop_while(function) do
    if function.() do
      loop_while(function)
    end
  end
end

BlackjackGame.start_game()
