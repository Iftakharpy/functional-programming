# -----------------------------------------------------
# Part 1
# -----------------------------------------------------
given_string = "99 bottles of beer on the wall"
word_count = String.split(given_string, " ") |> Enum.count()
IO.puts("Number of words in \"#{given_string}\" string is #{word_count}")


# -----------------------------------------------------
# Part 2
# -----------------------------------------------------
defmodule PigLatin do

  @doc """
  Given a `phrase`, translates it a word at a time to Pig Latin.
  * The casing of the original word is preserved.
  * Ending punctuation is preserved too.
  """
  def pig_latinize(phrase) do
    phrase
    |> String.split(" ")
    |> Enum.map(&pig_latinize_word/1)
    |> Enum.join(" ")
  end


  @doc """
  Given a `word`, translates it to Pig Latin.

  The function first splits the given word into the word itself and the ending punctuation.
  In the next step, it classifies the word beginning as a vowel, a consonant, or something else.
  Then it translates the word according to the classification. Then string concatenation
  is done with the punctuation. At the last step the original word casing is restored.
  """
  def pig_latinize_word(original_word) do
    {word, ending_punctuation} = split_word_and_ending_punctuation(original_word)

    pig_latin_word =
      case classify_word_beginning(word) do
        {:vowel, _} ->
          word <> "ay" <> ending_punctuation

        {:consonant, consonant} ->
          word = String.slice(word, String.length(consonant), String.length(word))
          word <> consonant <> "ay" <> ending_punctuation

        {:other, _} ->
          word <> ending_punctuation
      end

    pig_latin_word =
      if word_capitalized?(original_word) do
        String.capitalize(pig_latin_word)
      else
        pig_latin_word
      end

    pig_latin_word
  end

  def word_capitalized?(word) do
    String.slice(word, 0, 1) == String.slice(word, 0, 1) |> String.upcase()
  end

  def split_word_and_ending_punctuation(word) do
    %{
      "word" => word,
      "punctuation" => punctuation
    } = Regex.named_captures(~r/(?<word>.*?)(?<punctuation>[[:punct:]]*$)/, word)

    {word, punctuation}
  end


  def classify_word_beginning(word) do
    if (consonant = get_starting_consonant_sequence(word)) !== nil do
      consonant
    else
      if (vowel = get_starting_vowel_sequence(word)) !== nil do
        vowel
      else
        {:other, ""}
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

  def get_starting_consonant_sequence(word) do
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
        {:consonant, String.slice(word, 0, split_length)}
      else
        nil
      end
    end)
  end
end



given_phrase = "Pattern Matching with Elixir. Remember that equals sign is a match operator, not an assignment"

IO.puts(PigLatin.pig_latinize(given_phrase))
