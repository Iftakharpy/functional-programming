# -----------------------------------------------------
# Part 1
# -----------------------------------------------------
num_1 = IO.gets("Enter a number: ") |> String.trim() |> String.to_integer()

if rem(num_1, 3) == 0 do
  IO.puts("The number is evenly divisible by 3")
else
  if rem(num_1, 5) == 0 do
    IO.puts("The number is evenly divisible by 5")
  else
    if rem(num_1, 7) == 0 do
      IO.puts("The number is evenly divisible by 7")
    else
      divisor = Enum.find(2..num_1, fn x -> rem(num_1, x) == 0 end)
      IO.puts("The number is evenly divisible by #{divisor}")
    end
  end
end

# -----------------------------------------------------
# Part 2
# -----------------------------------------------------
add = fn a, b when is_bitstring(a) and is_bitstring(b) ->
  a <> b
  a, b -> a + b
end


IO.puts("add.(\"Hello\", \" World\"): #{add.("Hello", " World")}")
IO.puts("add.(3, 9.3): #{add.(3, 9.3)}")
