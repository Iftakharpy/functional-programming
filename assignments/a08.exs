defmodule PeriodicalTimer do
  use GenServer

  # Client API
  def start_link(%{callback_func: callback_func, interval_ms: interval_ms} = state)
       when is_function(callback_func, 0) and is_integer(interval_ms) and interval_ms > 0 do
    GenServer.start_link(__MODULE__, Map.put(state, :timer_ref, nil))
  end

  def cancel_timer(pid) do
    GenServer.call(pid, :cancel)
  end

  # Server API
  @impl true
  def init(state) do
    timer_ref = schedule_callback(self(), state)
    {:ok, %{state | timer_ref: timer_ref}}
  end

  @impl true
  def handle_call(:cancel, _from, state) do
    Process.cancel_timer(state[:timer_ref])
    {:stop, :normal, :stopped, state}
  end

  @impl true
  def handle_info(
        :call_callback,
        %{:callback_func => callback_func, :interval_ms => interval_ms} = state
      ) do
    case callback_func.() do
      :cancel ->
        send(self(), :cancel)
        {:noreply, state}

      _ ->
        timer_ref = Process.send_after(self(), :call_callback, interval_ms)
        {:noreply, %{state | timer_ref: timer_ref}}
    end
  end

  @impl true
  def handle_info(:cancel, state) do
    Process.cancel_timer(state[:timer_ref])
    {:stop, :normal, state}
  end

  defp schedule_callback(pid, state) do
    interval_ms = state[:interval_ms]
    Process.send_after(pid, :call_callback, interval_ms)
  end
end


print_rand_func = fn -> IO.puts("#{:rand.uniform()}") end
interval_ms = 300
{:ok, pid} = PeriodicalTimer.start_link(%{callback_func: print_rand_func, interval_ms: interval_ms})

IO.puts("PeriodicTimer started with pid: #{inspect(pid)}")
IO.gets("Press enter to cancel the timer\n\n")
# PeriodicalTimer.cancel_timer(pid)
IO.puts("Process #{inspect(pid)} alive? #{inspect(Process.alive?(pid))}")
