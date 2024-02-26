defmodule TCPClient do
  require Logger

  def start(host \\ ~c"192.168.1.73", port \\ 4000)
      when is_integer(port) and port >= 1024 and port <= 4915 do
    {:ok, socket} = :gen_tcp.connect(host, port, [:binary, packet: :line, active: false])
    Logger.info("Connected to #{host}:#{port}")
    :timer.sleep(100)

    case init_socket_connection_with_name(socket) do
      :ok ->
        :ok

      :error ->
        :gen_tcp.close(socket)
        Process.exit(self(), :normal)
    end

    receiver = spawn_link(fn -> server_message_loop(socket) end)
    _sender = spawn_link(fn -> user_input_loop(socket) end)

    wait_until_process_dies(receiver)
  end

  defp init_socket_connection_with_name(socket) do
    case :gen_tcp.recv(socket, 0, :timer.seconds(10)) do
      {:ok, "What's your name?\n"} ->
        name = IO.gets("What's your name? ") |> String.trim()
        :gen_tcp.send(socket, "#{name}\n")
        case read_line(socket) do
          :ok -> init_socket_connection_with_name(socket)
          :error -> :error
        end

      {:ok, "OK: Name accepted.\n"} ->
        :ok

      {:ok, msg} ->
        Logger.error(msg)
        :error

      {:error, :closed} ->
        Logger.error("Server closed the connection")
        :error

      {:error, reason} ->
        Logger.error("Error: #{reason}")
        :error
    end
  end

  defp wait_until_process_dies(pid) do
    receive do
    after
      300 ->
        if Process.alive?(pid) do
          wait_until_process_dies(pid)
        end
    end
  end

  defp read_line(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        data |> String.trim() |> IO.puts()
        :ok

      {:error, reason} ->
        "Error: #{reason}" |> Logger.error()
        :error
    end
  end

  defp server_message_loop(socket) do
    case read_line(socket) do
      :ok -> server_message_loop(socket)
      :error -> nil
    end
  end

  defp user_input_loop(socket) do
    :timer.sleep(100)
    message = IO.gets("> ") |> String.trim()

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
