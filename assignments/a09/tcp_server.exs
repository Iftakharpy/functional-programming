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
        # Ask for the client's name and wait for a response for 1 minute
        :gen_tcp.send(client_socket, "What's your name?\n")

        client_name =
          case :gen_tcp.recv(client_socket, 0, :timer.minutes(1)) do
            {:ok, name} ->
              name |> String.trim()

            {:error, _reason} ->
              :gen_tcp.close(client_socket)
              Process.exit(self(), :normal)
          end

        # Store the client's name and socket in the ETS table to identify the client
        # this will be used to broadcast messages to all clients by their name
        :ets.insert_new(:connected_client_names, {client_socket, client_name})
        Logger.info("#{client_name} connected")

        serve(client_socket, client_name)
      end)

    :gen_tcp.controlling_process(client_socket, client_connection_process)
    spawn(fn -> monitor_client_connection(client_connection_process, client_socket) end)

    loop_acceptor(listening_socket)
  end

  defp monitor_client_connection(pid, socket) do
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} ->
        :ets.delete(:connected_client_names, socket)
    end
  end

  defp serve(client_socket, client_name) do
    msg = read_line(client_socket)

    case msg do
      {:ok, data} ->
        client_sockets = :ets.tab2list(:connected_client_names)

        client_sockets
        |> Enum.each(fn {socket, name} ->
          if socket != client_socket do
            write_line(socket, "#{client_name}: #{data}")
          end
        end)

        serve(client_socket, client_name)

      {:error, _reason} ->
        Logger.info("Dropped connection with #{client_name}")
    end

    :gen_tcp.close(client_socket)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, text) do
    :gen_tcp.send(socket, text)
  end
end

Application.ensure_all_started([:wx, :runtime_tools, :observer])
:observer.start()

TCPServer.start(4000)
IO.gets("Press enter to exit\n")
# Cleanup
:ets.delete(:connected_client_names)
