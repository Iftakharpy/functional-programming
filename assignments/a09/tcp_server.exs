defmodule TCPServer do
  require Logger

  def start(port \\ 4000) when is_integer(port) and port >= 1024 and port <= 4915 do
    children = [
      {Task.Supervisor, name: TCPServer.ClientConnectionSupervisor},
      Supervisor.child_spec({Task, fn -> accept(port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: TCPServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp accept(port) do
    {:ok, listening_socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Listening on port #{port}")

    # Stores names in {socket, name} format
    :ets.new(:connected_client_names, [:set, :public, :named_table])

    loop_acceptor(listening_socket)
  end

  defp loop_acceptor(listening_socket) do
    {:ok, client_socket} = :gen_tcp.accept(listening_socket)

    {:ok, client_connection_process} =
      Task.Supervisor.start_child(TCPServer.ClientConnectionSupervisor, fn ->
        case ask_unique_name_for_new_client_socket(client_socket) do
          {:ok, client_name} ->
            # Store the client's name and socket in the ETS table to identify the client
            # this will be used to broadcast messages to all clients by their name
            :ets.insert_new(:connected_client_names, {client_socket, client_name})
            write_line(client_socket, "OK: Name accepted.")
            Logger.info("#{client_name} connected")

            broadcast_message(
              client_socket,
              "#{client_name} has joined the chat",
              MapSet.new([client_socket])
            )

            greet_new_client(client_socket, client_name)
            serve(client_socket, client_name)

          {:error, reason} ->
            write_line(client_socket, "ERROR: #{reason}")
            :gen_tcp.shutdown(client_socket, :write)
        end
      end)

    :gen_tcp.controlling_process(client_socket, client_connection_process)
    spawn(fn -> monitor_client_connection(client_connection_process, client_socket) end)

    loop_acceptor(listening_socket)
  end

  defp ask_unique_name_for_new_client_socket(client_socket, attempt \\ 1) do
    cond do
      attempt > 3 ->
        {:error, "Failed to get a unique name after 3 attempts!"}

      true ->
        # Ask for the client's name and wait for a response for 1 minute
        :gen_tcp.send(client_socket, "What's your name?\n")

        case :gen_tcp.recv(client_socket, 0, :timer.minutes(1)) do
          {:ok, name} ->
            with name <- String.trim(name),
                 true <- not Regex.match?(~r<^$|\s+>, name) do
              case :ets.match_object(:connected_client_names, {:"$1", name}) do
                [] ->
                  {:ok, name}

                _ ->
                  write_line(client_socket, "ERROR: Name already taken.")
                  ask_unique_name_for_new_client_socket(client_socket, attempt + 1)
              end
            else
              _ ->
                write_line(client_socket, "ERROR: Name is invalid.")
                ask_unique_name_for_new_client_socket(client_socket, attempt + 1)
            end

          {:error, :timeout} ->
            {:error, "Client didn't respond in time."}

          {:error, reason} ->
            {:error, "Error #{reason} occurred while initiating connection."}
        end
    end
  end

  defp monitor_client_connection(pid, socket) do
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} ->
        :gen_tcp.close(socket)
        :ets.delete(:connected_client_names, socket)
    end
  end

  defp serve(client_socket, client_name) do
    msg = read_line(client_socket)

    case msg do
      {:ok, data} ->
        if String.starts_with?(data, "COMMAND") and String.ends_with?(data, ";\n") do
          command = String.trim_leading(data, "COMMAND ") |> String.trim_trailing(";\n")

          case parse_command(command) do
            {:ok, command} ->
              case run_command(command, client_socket, client_name) do
                :ok ->
                  write_line(client_socket, "OK: COMMAND EXECUTED")

                {:error, reason} ->
                  write_line(client_socket, "ERROR (OCCURRED WHILE EXECUTION): #{reason}")
              end

            {:error, reason} ->
              write_line(client_socket, "ERROR (OCCURRED WHILE PARSING): #{reason}")
          end
        else
          broadcast_message(client_socket, "#{client_name}: #{data}", MapSet.new([client_socket]))
        end

        serve(client_socket, client_name)

      {:error, _reason} ->
        broadcast_message(
          client_socket,
          "#{client_name} has left the chat",
          MapSet.new([client_socket])
        )

        Logger.info("Dropped connection with #{client_name}")
    end

    :gen_tcp.shutdown(client_socket, :write)
  end

  defp greet_new_client(client_socket, client_name) do
    messages = "Welcome to the chat, #{client_name}!\n" <> command_help()
    write_line(client_socket, messages)
  end

  defp command_help do
    "\n" <>
      "There are 4 supported commands you can use:\n" <>
      "  HELP - to get this help message about available commands\n" <>
      "  GET USERS - to get the list of connected users\n" <>
      "  SET NAME <name> - to set your name\n" <>
      "  KICK USER <name> - to kick a user\n" <>
      "\n" <>
      "Note: all commands are case sensitive.\n" <>
      "\n" <>
      "Syntax: COMMAND <command>;\n" <>
      "Example: COMMAND GET USERS;\n"
  end

  defp parse_command(command) do
    case String.split(command, " ") do
      ["HELP"] -> {:ok, {:help}}
      ["GET", "USERS"] -> {:ok, {:get, :users}}
      ["SET", "NAME", name] -> {:ok, {:set, :name, name}}
      ["KICK", "USER", name] -> {:ok, {:kick, :user, name}}
      _ -> {:error, "Unknown command"}
    end
  end

  defp run_command({:help}, client_socket, _client_name) do
    write_line(client_socket, command_help())
    :ok
  end

  defp run_command({:get, :users}, client_socket, _client_name) do
    users =
      :ets.tab2list(:connected_client_names)
      |> Enum.map(fn {_, name} -> name end)
      |> Enum.join(", ")

    write_line(client_socket, users)
    :ok
  end

  defp run_command({:set, :name, name}, client_socket, client_name) do
    :ets.insert(:connected_client_names, {client_socket, name})

    broadcast_message(
      client_socket,
      "SET NAME: #{client_name} -> #{name}",
      MapSet.new([client_socket])
    )

    :ok
  end

  defp run_command({:kick, :user, name}, client_socket, client_name) do
    case :ets.match_object(:connected_client_names, {:"$1", name}) do
      [{candidate_socket, _candidate_name}] ->
        broadcast_message(
          client_socket,
          "KICK USER: #{name} by #{client_name}"
        )

        :gen_tcp.shutdown(candidate_socket, :write)
        :ok

      [] ->
        {:error, "User not found!"}
    end
  end

  defp run_command(_, _client_socket, _client_name) do
    {:error, "Can't run unknown command!"}
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, text) do
    :gen_tcp.send(socket, "#{text}\n")
  end

  defp broadcast_message(_client_socket, msg, exclude_sockets \\ MapSet.new()) do
    client_sockets = :ets.tab2list(:connected_client_names)

    client_sockets
    |> Enum.each(fn {socket, _name} ->
      if not MapSet.member?(exclude_sockets, socket) do
        write_line(socket, msg)
      end
    end)
  end
end

Application.ensure_all_started([:wx, :runtime_tools, :observer])
:observer.start()

TCPServer.start(4000)
IO.gets("Press enter to exit\n")
# Cleanup
:ets.delete(:connected_client_names)
