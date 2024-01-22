is_prime? = fn num ->
  prime? =
    Enum.find_value(2..(num - 1), :prime, fn n ->
      if rem(num, n) == 0 do
        :not_prime
      else
        nil
      end
    end)

  case prime? do
    :prime -> true
    :not_prime -> false
  end
end

get_biggest_prime = fn start, stop when start >= 2 and start < stop ->
  Enum.find(stop..start, fn num -> is_prime?.(num) end)
end

biggest_prime = get_biggest_prime.(2, 100)

IO.puts(biggest_prime)

IO.gets("Enter some text: ")
