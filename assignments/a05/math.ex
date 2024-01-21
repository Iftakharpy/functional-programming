defmodule Math do
  def add(a, b) do
    info(a, b, :add)
    a + b
  end

  def sub(a, b) do
    info(a, b, :sub)
    a - b
  end

  def mul(a, b) do
    info(a, b, :mul)
    a * b
  end

  def div(a, b) do
    info(a, b, :div)
    Kernel./(a, b)
  end

  def rem(a, b) do
    info(a, b, :rem)
    Kernel.rem(a, b)
  end

  def pow(a, b) do
    info(a, b, :pow)
    a ** b
  end

  defp info(a, b, operation) do
    log_statement = case operation do
      :add -> "Adding #{a} and #{b}"
      :sub -> "Subtracting #{b} from #{a}"
      :mul -> "Multiplying #{a} and #{b}"
      :div -> "Dividing #{a} by #{b}"
      :rem -> "Remainder of #{a} and #{b}"
      :pow -> "Raising #{a} to the power of #{b}"
      _ -> "Unknown operation"
    end

    IO.puts(log_statement)
    log_statement
  end
end
