#------------------------------------
# Part 1
#------------------------------------
# Integer variable
int_var = 123
IO.puts(int_var)

# Get user input
user_input = IO.gets("Enter some text: ")
IO.puts("You said: #{String.trim(user_input)}")


#------------------------------------
# Part 2
#------------------------------------
div_res = 154 / 74
IO.puts("154 / 74: #{div_res}")
IO.puts("154 / 74 rounded: #{round(div_res)}")
IO.puts(("154 / 74 integer part: #{trunc(div_res)}"))


#------------------------------------
# Part 3
#------------------------------------
user_input = IO.gets("Enter some text: ") |> String.trim_trailing()
IO.puts("You entered #{String.length(user_input)} characters")

reversed_user_input = String.reverse(user_input)
IO.puts("Reversed: #{reversed_user_input}")

replaced_foo = String.replace(user_input, "foo", "bar")
IO.puts(("Replaced foo with bar: #{replaced_foo}"))


#------------------------------------
# Part 4
#------------------------------------
multiply_3_nums = fn a, b, c -> a*b*c end

num_1 = IO.gets("Enter number 1: ") |> String.trim() |> String.to_integer()
num_2 = IO.gets("Enter number 2: ") |> String.trim() |> String.to_integer()
num_3 = IO.gets("Enter number 3: ") |> String.trim() |> String.to_integer()
IO.puts("multiply_3_nums(#{num_1}, #{num_2}, #{num_3}): #{multiply_3_nums.(num_1, num_2, num_3)}")


concat_2_lists = fn l1, l2 -> l1 ++ l2 end

IO.inspect(concat_2_lists.([1, 3, 4, 255], [1, 5, 883]))

initial_tuple = {:ok, :fail}
initial_tuple = Tuple.append(initial_tuple,:cancelled)
IO.inspect(initial_tuple)
