# Framer

A few helper classes to resize iodata streams and iolists.

If you do not want to add another dependency, feel free to steal any of the
functions. They aren't long.

<!-- MDOC -->

The two main functions are:

- `resize_stream/2` for resizing elements of an iodata stream
- `resize/2` for resizing elements of an iodata list

## Examples

Resizing a iodata stream:

```elixir
  iex> stream = ["The brown", " fox", ["that ", "jumped"], " up."]
  iex> Framer.resize_stream(stream, 5) |> Enum.to_list()
  [["The b"], ["rown", " "], ["fox", "th"], ["at ", "ju"], ["mped", " "], ["up."]]
```

Resizing an iolist:

```elixir
  iex> enum = ["Hello ", "World"]
  iex> Framer.resize(enum, 4)
  [["Hell"], ["o ", "Wo"], ["rld"]]
```

<!-- MDOC -->

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `framer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:framer, "~> 0.1.0"}
  ]
end
```

## Caution

I have not benchmarked any of those functions, nor tested heavily in a production
environment. Please proceed with caution.

## Contributing

Please submit a PR or open an issue if you come across a bug or hit
performance bottlenecks.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/framer](https://hexdocs.pm/framer).
