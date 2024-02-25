defmodule TCPClient do
  require Logger

  def start(host \\ ~c"192.168.1.73", port \\4000) when is_integer(port) and port>=1024 and port<=4915 do
    {:ok, socket} = :gen_tcp.connect(host, port, [:binary, packet: :line, active: false])
    Logger.info("Connected to #{host}:#{port}")
    :timer.sleep(100)

    {:ok, data} = :gen_tcp.recv(socket, 0, :timer.seconds(10))
    case data do
      "What's your name?\n" ->
        name = IO.gets("What's your name? ") |> String.trim
        :gen_tcp.send(socket, "#{name}\n")
      _ ->
        Logger.error("Unexpected data: #{inspect(data)}")
        :gen_tcp.close(socket)
        Process.exit(self(), :normal)
    end

    receiver = spawn_link(fn -> server_message_loop(socket) end)
    _sender = spawn_link(fn -> user_input_loop(socket) end)

    wait_until_process_dies(receiver)
  end

  defp wait_until_process_dies(pid) do
    receive do
    after
      300 -> if Process.alive?(pid) do
        wait_until_process_dies(pid)
      end
    end
  end

  defp server_message_loop(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        IO.puts(data |> String.trim) # Print the message from the server
        server_message_loop(socket)
      {:error, :closed} ->
        Logger.info("Server closed the connection")
        :ok
      {:error, reason} ->
        Logger.error("Error: #{reason}")
        :ok
    end
  end

  defp user_input_loop(socket) do
    :timer.sleep(100)
    message = IO.gets("> ") |> String.trim

    if message == "exit" do
      :gen_tcp.close(socket)
      Process.exit(self(), :normal)
    else
      :gen_tcp.send(socket, "#{message}\n")
      user_input_loop(socket)
    end
  end
end


TCPClient.start()
