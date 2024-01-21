alias Calculator


expression_evaluator_loop = fn callback_fnp ->
  expression = IO.gets("=> ") |> String.trim()

  case Calculator.calc(expression) do
    {:ok, result} ->
      IO.puts("Result: #{result}")
      IO.puts("")
      callback_fnp.(callback_fnp)
    {:error, error} ->
      IO.puts("Error: #{error}")
  end
end

expression_evaluator_loop.(expression_evaluator_loop)
