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
  "Pattern Matching with Elixir. Remember that equals sign is a match operator, not an assignment"

defmodule PigLatin do
  @vowels MapSet.new(["a", "e", "i", "o", "u", "yt", "xr"])
  @min_length_of_vowel Enum.min_by(@vowels, fn v -> String.length(v) end) |> String.length()
  @max_length_of_vowel Enum.max_by(@vowels, fn v -> String.length(v) end) |> String.length()

  consonants = MapSet.new(["ch", "qu", "squ", "th", "thr", "sch", "b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "x", "z"])
  min_length_of_consonant = Enum.min_by(consonants, fn c -> String.length(c) end) |> String.length()
  max_length_of_consonant = Enum.max_by(consonants, fn c -> String.length(c) end) |> String.length()

  def pig_latinize(phrase) do
    phrase
      |> String.split(" ")
      |> Enum.find(fn word -> word end)
      |> Enum.join(" ")
  end

  def get_starting_vowel_sequence(word) do
    IO.puts("#{@min_length_of_vowel} #{@max_length_of_vowel}")
    Enum.find_value(Enum.to_list(@min_length_of_vowel..@max_length_of_vowel), fn i ->
      String.slice(word, 0, i)
      |> fn v -> if MapSet.member?(vowels, v) do v end end
    end)
  end
end


PigLatin.pig_latinize(given_phrase) |> IO.inspect()
