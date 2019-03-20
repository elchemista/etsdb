defmodule ETSDB do
  @type t :: module

  @doc false
  defmacro __using__(config: opt) do
    quote do

      @behaviour ETSDB
      use GenServer

      def get(attrs) do
        with {:ok, indx} <- __MODULE__.handle_get(attrs),
             [{_, data}] <- :ets.lookup(ets_ref(), indx) do
          {:ok, data}
        end
      end

      def query(attrs) do
        with {:ok, query} <- __MODULE__.handle_query(attrs) do
          :ets.match(ets_ref(), query)
          |> Enum.reduce([], fn [ele], acc -> [ele | acc] end)
        end
      end

      def delete(attrs) do
        with {:ok, indx} <- __MODULE__.handle_delete(attrs) do
          GenServer.cast(ETSDB.Persist, {:persist, :delete})
          GenServer.call(__MODULE__, {:delete, indx})
        end
      end

      def insert(attrs) do
        with {:ok, data} <- __MODULE__.handle_insert(attrs) do
          GenServer.cast(ETSDB.Persist, {:persist, :insert})
          GenServer.call(__MODULE__, {:insert, data})
        end
      end

      # Private fn

      defp ets_ref(), do: Application.get_env(:etsdb, __MODULE__)

      def start_link(), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

      @doc false
      @impl true
      def init(_) do
        file = "#{Application.get_env(:etsdb, :path)}/#{__MODULE__}"

        {:ok, tab} =
          if File.exists?(file),
            do: :ets.file2tab(String.to_charlist(file)),
            else: {:ok, :ets.new(__MODULE__, unquote(opt))}

        Application.put_env(:etsdb, __MODULE__, tab, persistent: true)
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
  end

  @callback handle_insert(any) :: {:ok, tuple} | {:error, any}

  @callback handle_get(any) :: {:ok, tuple} | {:error, any}

  @callback handle_delete(any) :: {:ok, tuple} | {:error, any}

  @callback handle_query(any) :: {:ok, tuple} | {:error, any}
end
