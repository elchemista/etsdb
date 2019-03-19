defmodule ETSDB do
  @moduledoc """
  Public API for interacting with ETS database
  """

  def get(id) do
    with {:ok, ref} <- get_db_ref,
         [{_, data}] <- :ets.lookup(ref, id) do
      {:ok, data}
    end
  end

  def query(query) do
    with {:ok, ref} <- get_db_ref do
      :ets.match(ref, query)
      |> Enum.reduce([], fn [ele], acc -> [ele | acc] end)
    end
  end

  def delete(id) do
    GenServer.cast(ETSDB.Persist, {:persist, :delete})
    GenServer.call(ETSDB.DB, {:delete, id})
  end

  def insert(data) do
    GenServer.cast(ETSDB.Persist, {:persist, :insert})
    GenServer.call(ETSDB.DB, {:insert, data)
  end

  # Private fn

  defp get_db_ref(db) do
    with nil <- Application.get_env(:etsdb, :db),
         :undefined <- :ets.whereis(db) do
      {:error, :db}
    else
      ref -> {:ok, ref}
    end
  end
end
