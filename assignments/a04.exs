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
lookup_by_name = fn name -> Enum.find(color_values, fn {k, _} -> to_string(k)|>String.upcase == name|>String.upcase end) end
lookup_by_value = fn value -> Enum.find(color_values, fn {_, v} -> v|>String.upcase == value|>String.upcase end) end

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
    lookup_result = cond do
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

user_color_look_up_loop.()


# -----------------------------------------------------
# Part 2
# -----------------------------------------------------
