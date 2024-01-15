# -----------------------------------------------------
# Part 1
# -----------------------------------------------------
given_string = "99 bottles of beer on the wall"
word_count = String.split(given_string, " ") |> Enum.count()
IO.puts("Number of words in \"#{given_string}\" string is #{word_count}")

# -----------------------------------------------------
# Part 2
# -----------------------------------------------------
given_phrase =
  "Pattern xray Matching with Elixir. Remember that equals sign is a match operator, not an assignment"

defmodule PigLatin do
  def pig_latinize(phrase) do
    phrase
    |> String.split(" ")
    |> Enum.map(fn word -> pig_latinize_word(word, classify_word_beginning(word)) end)
    |> Enum.join(" ")
  end

  def pig_latinize_word(word, clasification) do
    case clasification do
      {:vowel, _vowel} -> word <> "ay"
      {:consonent, consonent} -> String.replace(word, consonent,"") <> consonent <> "ay"
      _ -> word
    end
  end


  def classify_word_beginning(word) do
    consonent = get_starting_consonent_sequence(word)
    vowel = get_starting_vowel_sequence(word)

    if consonent !== nil do
      consonent
    else
      if vowel !== nil do
        vowel
      else
        {:symbol, String.slice(word, 0, 1)}
      end
    end
  end

  def get_starting_vowel_sequence(word) do
    vowels = MapSet.new(["a", "e", "i", "o", "u", "yt", "xr"])
    min_length_of_vowel = Enum.min_by(vowels, fn v -> String.length(v) end) |> String.length()

    max_length_of_vowel =
      min(
        String.length(word),
        Enum.max_by(vowels, fn v -> String.length(v) end) |> String.length()
      )

    Enum.find_value(min_length_of_vowel..max_length_of_vowel, fn split_length ->
      transformed_word = String.downcase(word)
      candidate_to_check = String.slice(transformed_word, 0, split_length)

      if MapSet.member?(vowels, candidate_to_check) do
        {:vowel, String.slice(word, 0, split_length)}
      else
        nil
      end
    end)
  end

  def get_starting_consonent_sequence(word) do
    consonants =
      MapSet.new([
        "squ",
        "thr",
        "sch",
        "ch",
        "qu",
        "th",
        "b",
        "c",
        "d",
        "f",
        "g",
        "h",
        "j",
        "k",
        "l",
        "m",
        "n",
        "p",
        "q",
        "r",
        "s",
        "t",
        "v",
        "w",
        "x",
        "z"
      ])

    min_length_of_consonant =
      Enum.min_by(consonants, fn c -> String.length(c) end) |> String.length()

    max_length_of_consonant =
      min(word, Enum.max_by(consonants, fn c -> String.length(c) end) |> String.length())

    Enum.find_value(max_length_of_consonant..min_length_of_consonant//-1, fn split_length ->
      transformed_word = String.downcase(word)
      candidate_to_check = String.slice(transformed_word, 0, split_length)

      if MapSet.member?(consonants, candidate_to_check) do
        {:consonent, String.slice(word, 0, split_length)}
      else
        nil
      end
    end)
  end
end

IO.puts(PigLatin.pig_latinize(given_phrase))
