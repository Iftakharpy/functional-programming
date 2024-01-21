defmodule Calculator do
  @parser_regex ~r/(?<num_1>\-?\d+(?:\.\d+)?)\s*(?<operator>\+|\-|\/|\*|\*\*|\%)\s*(?<num_2>\-?\d+(?:\.\d+)?)/

  def calc(expression) do
    # Parse expression using regex
    case Regex.named_captures(@parser_regex, expression) do
      %{"num_1" => num_1, "operator" => operator, "num_2" => num_2} ->
        # Parse numbers
        try do
          {num_1, _} = if String.contains?(num_1, ".") do
            Float.parse(num_1)
          else
            Integer.parse(num_1)
          end
          {num_2, _} = if String.contains?(num_2, ".") do
            Float.parse(num_2)
          else
            Integer.parse(num_2)
          end

          # Perform operation
          try do
            alias Math

            evaluation_result = case operator do
              "+" -> Math.add(num_1, num_2)
              "-" -> Math.sub(num_1, num_2)
              "*" -> Math.mul(num_1, num_2)
              "/" -> Math.div(num_1, num_2)
              "%" -> Math.rem(num_1, num_2)
              "**" -> Math.pow(num_1, num_2)
              _ -> "Unknown operation"
            end

            cond do
              is_bitstring(evaluation_result) -> {:error, evaluation_result}
              true -> {:ok, evaluation_result}
            end
          rescue
            _ -> {:error, "Error occurred while performing operation"}
          end
        rescue
          _ -> {:error, "Error occurred while parsing numbers"}
        end
      _ ->
        {:error, "Invalid expression"}
    end
  end
end
