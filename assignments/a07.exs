# Assignment 7: Blackjack

# Blackjack is implemented as a simple text-based game. Dealer and Player
# modules are implemented as processes. The game is started by calling
# BlackjackGame.start_game().

# Player can choose to hit or stand. Dealer must hit until score is 17 or higher.
# Ace can be 1 or 11, the score will be in player's favor.


# At first the dealer deals two cards to the player and two cards to himself.
# All cards are visible to the player including dealer's cards.

# The, dealer asks player to hit or stand. Until player stands, or busts.
# If player busts, dealer wins. If player stands, dealer must hit until dealer's
# score is 17 or higher. If dealer busts, player wins. Otherwise, the one with
# higher score wins. If scores are equal, it's a tie.

# Dealer is responsible for dealing cards, validating the game state and
# managing the game state.

# Player is responsible for asking player to hit or stand. And sending the choice
# to the dealer.

# BlackjackGame is responsible for initializing and shutting down the
# Player and Dealer processes.


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
    send(:dealer_process, {:validate_game})
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
    new_state =
      receive do
        {:deal_card, :to_player} ->
          {[card | _], remaining_cards} = state.current_shoe |> Enum.split(1)

          state = %{
            state
            | player_hand: [card | state.player_hand],
              current_shoe: remaining_cards
          }

          if calculate_score(state.player_hand) > 21 do
            %{state | dealers_turn?: true}
          else
            state
          end

        {:deal_card, :to_dealer} ->
          {[card | _], remaining_cards} = state.current_shoe |> Enum.split(1)
          %{state | dealer_hand: [card | state.dealer_hand], current_shoe: remaining_cards}

        {:stop_loop} ->
          nil

        {:validate_game} ->
          cond do
            not state.dealers_turn? ->
              IO.puts("Dealer's hand: #{hand_to_string(state.dealer_hand)}")
              IO.puts("Player's hand: #{hand_to_string(state.player_hand)}")
              send(:player_process, {:players_turn})

              updated_state =
                receive do
                  {:player_plays, :hit} ->
                    send(:dealer_process, {:deal_card, :to_player})
                    state

                  {:player_plays, :stand} ->
                    %{state | dealers_turn?: true}
                end

              send(:dealer_process, {:validate_game})
              updated_state

            state.dealers_turn? ->
              case game_result(state.dealer_hand, state.player_hand) do
                {:game_continues, _} ->
                  if should_dealer_hit?(state.dealer_hand) do
                    send(:dealer_process, {:deal_card, :to_dealer})
                  end

                  send(:dealer_process, {:validate_game})
                  state

                {:game_ends, result} ->
                  IO.puts("")
                  IO.puts("---------------- Game result ----------------")
                  IO.puts("Dealer's hand: #{hand_to_string(state.dealer_hand)}")
                  IO.puts("Player's hand: #{hand_to_string(state.player_hand)}")
                  IO.puts("")

                  case result do
                    :player_busts ->
                      IO.puts("Player busts, dealer wins!")

                    :dealer_busts ->
                      IO.puts("Dealer busts, player wins!")

                    :tie ->
                      IO.puts("It's a tie!")

                    :player_wins ->
                      IO.puts("Player wins!")

                    :dealer_wins ->
                      IO.puts("Dealer wins!")
                  end

                  IO.puts("---------------------------------------------")
                  IO.puts("")

                  :game_ended
              end
          end
      end

    case new_state do
      nil ->
        nil

      :game_ended ->
        play_again? =
          IO.gets("Do you want to play again? ([y]/n): ")
          |> String.trim()
          |> String.downcase()

        play_again? =
          (String.length(play_again?) == 0 && "y") || play_again?

        case play_again? do
          "y" ->
            IO.puts("")
            IO.puts("Starting new game...")
            IO.puts("=============================================")
            IO.puts("")
            send(:dealer_process, {:validate_game})
            loop(initial_game_state())

          _ ->
            nil
        end

      _ ->
        loop(new_state)
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
  @spec count_aces(list[Card.t()]) :: integer()
  def count_aces(hand) do
    Enum.count(hand, fn card -> card.rank == "Ace" end)
  end

  @spec calculate_score(list[Card.t()]) :: integer()
  def calculate_score(hand) do
    score =
      hand
      |> Enum.map(& &1.rank)
      |> Enum.map(&@score_map[&1])
      |> Enum.sum()

    ace_count = count_aces(hand)

    if ace_count > 0 do
      Enum.reduce(1..ace_count, score, fn _, acc ->
        if acc > 21 do
          # Since an ace can be 1 or 11, and favours the player
          # we have to try to not bust by using lower score 1 instead of 11
          # lower score [11 - 10] = 1
          acc - 10
        else
          acc
        end
      end)
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
      {:players_turn} ->
        hit_or_stand? =
          IO.gets("Hit or stand? ([h]/s): ")
          |> String.trim()
          |> String.downcase()

        hit_or_stand? = (String.length(hit_or_stand?) == 0 && "h") || hit_or_stand?

        case hit_or_stand? do
          "h" ->
            send(:dealer_process, {:player_plays, :hit})
            loop()

          "s" ->
            send(:dealer_process, {:player_plays, :stand})
            loop()

          _ ->
            IO.puts("Invalid input, try again.")
            send(:player_process, {:players_turn})
            loop()
        end

      {:stop_loop} ->
        nil
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

    # If any of the processes are still alive, stop them
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
