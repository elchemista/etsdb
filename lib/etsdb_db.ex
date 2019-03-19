defmodule ETSDB.DB do
  @moduledoc false
  use GenServer

  @ets_config [:set, :protected, {:read_concurrency, true}]

  @name __MODULE__

  def start_link(), do: GenServer.start_link(@name, :ok, name: @name)

  @doc false
  @impl true
  def init(_) do
    file = Application.get_env(:etsdb, :filename)

    {:ok, tab} =
      if File.exists?(file),
        do: :ets.file2tab(String.to_charlist(file)),
        else: {:ok, :ets.new(:etsdb, @ets_config)}

    Application.put_env(:etsdb, :db, tab, persistent: true)
    {:ok, {tab, file}}
  end

  @doc false
  @impl true
  def handle_call(:persist, _from, {table, file} = state) do
    {:reply, :ets.tab2file(table, String.to_charlist(file)), state}
  end

  @doc false
  @impl true
  def handle_call(:load, _from, {_, file} = state) do
    with true <- File.exists?(file),
         {:ok, table} <- :ets.file2tab(file) do
      {:reply, {:loaded, file}, {table, file}}
    else
      _ -> {:reply, {:not_found, file}, state}
    end
  end

  @doc false
  @impl true
  def handle_call({:insert, data}, _from, {table, _} = state) when is_tuple(data) do
    {:reply, :ets.insert(table, data), state}
  end

  @doc false
  def handle_call({:delete, key}, _from, {table, _} = state) do
    {:reply, :ets.delete(table, key), state}
  end

  def handle_call(action, _from, state), do: {:reply, {:error, action}, state}
end
