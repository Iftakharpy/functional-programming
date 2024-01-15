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
