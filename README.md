# Etsdb

### Under development! 

Very simple ets db with persistence on file.
`use ETSDB, config: [:set, :protected, {:read_concurrency, true}]`

Absolute path where db file will be saved.
`config :etsdb, filename: "/tmp/ets_db"`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `etsdb` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:etsdb, github: "NeoAlchemist/etsdb"}
  ]
end
```