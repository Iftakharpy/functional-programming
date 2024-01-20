# -----------------------------------------------------
# Part 1
# -----------------------------------------------------
color_values = [
  red: "#FF0000",
  green: "#00FF00",
  blue: "#0000FF",
  white: "#FFFFFF",
  black: "#000000",
  cornSilk: "#FFF8DC",
  coral: "#FF7F50",
  crimson: "#DC143C",
  cadetBlue: "#5F9EA0",
  darkSlateGray: "#2F4F4F",
  lightSalmon: "#FFA07A"
]

color_values = color_values ++ [purple: 0x800080, yellow: 0xFFFF00, orange: 0xFFA500]

# Lookup functions
lookup_by_name = fn name ->
  Enum.find(color_values, fn {k, _} ->
    to_string(k) |> String.upcase() == name |> String.upcase()
  end)
end

lookup_by_value = fn value ->
  Enum.find(color_values, fn {_, v} -> v |> String.upcase() == value |> String.upcase() end)
end

user_color_look_up_loop = fn ->
  user_looks_up_color = fn recursive_fp ->
    query = IO.gets("Enter a color name(eg. red) or value(eg. #FF0000): ") |> String.trim()

    # Color lookup
    color_tuple =
      case String.slice(query, 0, 1) do
        "#" -> lookup_by_value.(query)
        _ -> lookup_by_name.(query)
      end

    # Format the result of the lookup
    lookup_result =
      cond do
        color_tuple == nil ->
          {:not_found, query}

        String.slice(query, 0, 1) == "#" ->
          {:lookup_by_value, elem(color_tuple, 0)}

        true ->
          {:lookup_by_name, elem(color_tuple, 1)}
      end

    # Decision to look up color again or exit
    case lookup_result do
      {:not_found, query} ->
        IO.puts("Could not find any color for your query `#{query}`")

      {:lookup_by_name, value} ->
        IO.puts("The value of #{query} color is #{value}")
        recursive_fp.(recursive_fp)

      {:lookup_by_value, name} ->
        IO.puts("The name of #{query} color is #{name}")
        recursive_fp.(recursive_fp)
    end
  end

  user_looks_up_color.(user_looks_up_color)
end

IO.puts("Welcome to the color lookup program!")
user_color_look_up_loop.()
IO.puts("Color lookup program exited!")
IO.puts("")


# -----------------------------------------------------
# Part 2
# -----------------------------------------------------
isbn_books = %{
  "9781680502992" => "Programming Elixir ≥ 1.6: Functional |> Concurrent |> Pragmatic |> Fun",
  "9781785881749" => "Learning Elixir",
  "9781617295027" => "Elixir in Action",
  "9781680508192" =>
    "Concurrent Data Processing in Elixir: Fast, Resilient Applications with OTP, GenStage, Flow, and Broadway",
  "9781680506617" =>
    "Designing Elixir Systems With OTP: Write Highly Scalable, Self-healing Software with Layers",
  "9781680507829" => "Testing Elixir: Effective and Robust Testing for Elixir and its Ecosystem"
}

isbn_books =
  Map.put(
    isbn_books,
    "9781680500417",
    "Metaprogramming Elixir: Write Less Code, Get More Done (and Have Fun!)"
  )

isbn_books =
  Map.merge(isbn_books, %{
    "1491956771" => "Introducing Elixir: Getting Started in Functional Programming"
  })

  format_isbn_book_info = fn isbn, book_title ->
    "ISBN: #{isbn} - #{book_title}"
  end

commands = %{
  list: %{
    description: "lists all books in the map.",
    fn: fn _command, isbn_books_map ->
      Enum.with_index(Map.to_list(isbn_books_map), fn {isbn_num, book_title}, idx ->
        IO.puts("#{idx + 1}. #{format_isbn_book_info.(isbn_num, book_title)}")
      end)

      isbn_books_map
    end
  },
  search: %{
    args: ["ISBN"],
    description: "searches a book with specified ISBN and prints book info.",
    fn: fn command, isbn_books_map ->
      [_cmd, isbn] = String.split(command, " ", parts: 2)

      book =
        Enum.find(Map.to_list(isbn_books_map), fn {isbn_num, _book_title} ->
          isbn == isbn_num
        end)

      if book != nil do
        IO.puts("Book found: #{format_isbn_book_info.(elem(book, 0), elem(book, 1))}")
      else
        IO.puts("Book not found.")
      end

      isbn_books_map
    end
  },
  add: %{
    args: ["ISBN", "Book Title"],
    description: "adds new book into the map.",
    fn: fn command, isbn_books_map ->
      [_cmd, data] = String.split(command, " ", parts: 2)
      [isbn_num, book_title] = String.split(data, ",", parts: 2)
      Map.put(isbn_books_map, isbn_num |> String.trim(), book_title |> String.trim())
    end
  },
  remove: %{
    args: ["ISBN"],
    description: "removes book with ISBN if found on map.",
    fn: fn command, isbn_books_map ->
      [_cmd, isbn_num] = String.split(command, " ", parts: 2)
      Map.delete(isbn_books_map, isbn_num)
    end
  },
  quit: %{
    description: "quits the program.",
    fn: fn _command, isbn_books_map ->
      exit(:shutdown)
      isbn_books_map
    end
  },
  help: %{
    description: "prints all available commands.",
    fn: fn _command, isbn_books_map -> isbn_books_map end
  }
}

commands =
  put_in(commands.help.fn, fn _command, isbn_books_map ->
    IO.puts("Available commands are:")

    Enum.each(Map.to_list(commands), fn {cmd, cmd_details} ->
      IO.puts("#{cmd} #{Map.get(cmd_details, :args, []) |> Enum.join(", ")}")
      IO.puts("  description: #{cmd_details.description}")
      IO.puts("")
    end)

    isbn_books_map
  end)

isbn_loop = fn isbn_books_map ->
  isbn = fn recursive_fnp, isbn_books_map, put_new_line ->
    if put_new_line do
      IO.puts("")
    end

    command = IO.gets("Enter a command: ") |> String.trim()
    cmd = String.split(command, " ", parts: 2) |> List.first()

    command_details = Map.get(commands, cmd |> String.to_atom())

    if command_details != nil do
      try do
        recursive_fnp.(recursive_fnp, command_details.fn.(command, isbn_books_map), true)
      rescue
        _ ->
          IO.puts("Error ocurred while running your command.")
          recursive_fnp.(recursive_fnp, isbn_books_map, true)
      end
    else
      IO.puts("Invalid command. Type `help` to see all available commands.")
      recursive_fnp.(recursive_fnp, isbn_books_map, true)
    end
  end

  IO.puts("Welcome to the ISBN book lookup program!")
  isbn.(isbn, isbn_books_map, false)
end

isbn_loop.(isbn_books)
