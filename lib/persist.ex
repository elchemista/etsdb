defmodule ETSDB.Persist do
  @moduledoc false
  defmodule State do
    @moduledoc false
    defstruct [:lock, :action, :timestamp]

    @opaque t() :: %__MODULE__{
              action: atom,
              lock: boolean,
              timestamp: tuple
            }
  end

  require Logger
  use GenServer
  @name __MODULE__

  def start_link(), do: GenServer.start_link(@name, [], name: @name)

  @doc false
  def state(), do: GenServer.call(@name, :state)

  @doc false
  @impl true
  def init(_), do: {:ok, {Process.monitor(ETSDB.DB), %State{lock: false}}}

  @doc false
  @impl true
  def handle_call(:state, _from, {_, status} = state), do: {:reply, status, state}
  
  @doc false
  @impl true
  def handle_cast({:persist, action}, {ref, _}) do
    state = %State{lock: true, action: action, timestamp: :os.timestamp}
    Process.send_after(self(), {:diff, state}, 5_000)
    {:noreply, {ref, state}}
  end

  @doc false
  @impl true
  def handle_info({:diff, diff}, {ref, state} = status) do
    case state do
      ^diff ->
        with {:error, _} <- GenServer.call(ETSDB.DB, :persist), do: Logger.error("ETSDB failed persist to file") 
        {:noreply, {ref, %State{lock: false}}}
      _ ->
        Process.send_after(self(), {:diff, state}, 5_000)
        {:noreply, status}
      end
  end

  @doc false
  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _}, {ref, state}) do
    Logger.error("ETSDB DOWN, Action:#{state.action} :: Lock: #{state.lock}") 
    # waiting 1 sec
    Process.sleep(1000)
    {:noreply,
     {Process.monitor(ETSDB.DB), %State{lock: false}}}
  end

  @doc false
  def handle_info(_, state), do: {:noreply, state}
end
