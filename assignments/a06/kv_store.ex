defmodule KVS do
  use Agent

  @doc """
  Starts a new bucket.
  """
  def start_link() do
    case Agent.start_link(fn -> %{} end, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      other_possibilities -> other_possibilities
    end
  end

  @doc """
  Stops the `bucket`.
  """
  def stop() do
    Agent.stop(__MODULE__)
  end

  @doc """
  Returns the current state of the `bucket`.
  """
  def get_state() do
    Agent.get(__MODULE__, & &1)
  end

  @doc """
  Resets the `bucket` to an empty map.
  """
  def reset() do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(key, default \\ nil) do
    Agent.get(__MODULE__, &Map.get(&1, key, default))
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  @doc """
  Deletes the `key` from the `bucket`.
  """
  def delete(key) do
    Agent.update(__MODULE__, &Map.delete(&1, key))
  end

  @doc """
  Returns `true` if the `bucket` contains the given `key`, `false` otherwise.
  """
  def contains?(key) do
    Agent.get(__MODULE__, &Map.has_key?(&1, key))
  end

  @doc """
  Returns `true` if the `bucket` is empty, `false` otherwise.
  """
  def empty?() do
    Agent.get(__MODULE__, &(Kernel.map_size(&1) == 0))
  end

  @doc """
  Returns all the keys in the `bucket`.
  """
  def keys() do
    Agent.get(__MODULE__, &Map.keys(&1))
  end

  @doc """
  Returns all the values in the `bucket`.
  """
  def values() do
    Agent.get(__MODULE__, &Map.values(&1))
  end

  @doc """
  Returns all the key-value pairs in the `bucket`.
  """
  def entries() do
    Agent.get(__MODULE__, &Map.to_list(&1))
  end

  @doc """
  Returns the number of key-value pairs in the `bucket`.
  """
  def size() do
    Agent.get(__MODULE__, &map_size(&1))
  end
end
