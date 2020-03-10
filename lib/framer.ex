defmodule Framer do
  @external_resource readme = Path.join([__DIR__, "../README.md"])

  @moduledoc readme
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(1)
             |> String.replace(~r(```elixir|```), "")

  @moduledoc since: "0.1.0"

  @doc ~S"""
  Resizes an `iodata` stream into a stream of equally sized frames.
  The last frame might be smaller.

  Returns an iodata stream.

  ## Example

    iex> stream = ["The brown", " fox", ["that ", "jumped"], " up."]
    iex> Framer.resize_stream(stream, 5) |> Enum.to_list()
    [["The b"], ["rown", " "], ["fox", "th"], ["at ", "ju"], ["mped", " "], ["up."]]
  """
  @spec resize_stream(iodata, pos_integer) :: Enumerable.t()
  def resize_stream(iodata, frame_size) do
    iodata
    |> Stream.concat([:finito])
    |> Stream.transform(
      [],
      fn
        :finito, acc ->
          {[acc], []}

        el, acc ->
          [rem | reversed_packs] =
            (acc ++ [el])
            |> List.flatten()
            |> resize([], frame_size)

          if IO.iodata_length(rem) == frame_size do
            {Enum.reverse([rem | reversed_packs]), []}
          else
            {Enum.reverse(reversed_packs), rem}
          end
      end
    )
  end

  @doc ~S"""
  Resizes an `iolist` into a new `iolist` with elements of `frame_size`.

  Returns a new iolist.

  ## Example

  iex> iolist = [?h, "el", ["l", [?o]], "world"]
  iex> Framer.resize(iolist, 3)
  [["h", "el"], ["l", "o", "w"], ["orl"], ["d"]]
  """
  @spec resize(iolist, pos_integer) :: Enumerable.t()
  def resize(iolist, frame_size) do
    iolist
    |> List.flatten()
    |> resize([], frame_size)
    |> Enum.reverse()
  end

  defp resize(iodata, acc, frame_size)
  defp resize([], acc, _), do: acc

  defp resize(iodata, acc, frame_size) do
    case next_frame(iodata, frame_size) do
      {[], rest} -> {acc, rest}
      {pack, rest} -> resize(rest, [pack | acc], frame_size)
    end
  end

  @doc ~S"""
  Returns a tuple containing the first frame of `frame_size` taken off
  the iolist and the reminder of the list.

  ## Exmaple

  iex> iolist = [?h, "el", ["l", [?o]], "world"]
  iex> Framer.next_frame(iolist, 3)
  {["h", "el"], [["l", [?o]], "world"]}

  When the whole iolist fits into a frame, return the io list with an empty
  remainder.

  iex> iolist = ["h", "ello"]
  iex> Framer.next_frame(iolist, 10)
  {["h", "ello"], []}
  """
  @spec next_frame(iolist, pos_integer) :: {[any], iolist}
  def next_frame(iolist, frame_size) do
    {frame, rem} = next_frame(iolist, [], frame_size)

    {frame |> Enum.reverse(), rem}
  end

  defp next_frame(iodata, tmp, frame_size)
  defp next_frame([], tmp, _), do: {tmp, []}

  defp next_frame([first_chunk | rest] = iodata, tmp, frame_size) do
    tmp_size = IO.iodata_length(tmp)

    if tmp_size == frame_size do
      {tmp, iodata}
    else
      binary = IO.iodata_to_binary([first_chunk])

      case split_binary(binary, frame_size - tmp_size) do
        {part, nil} -> next_frame(rest, [part | tmp], frame_size)
        {part, rem} -> next_frame([rem | rest], [part | tmp], frame_size)
      end
    end
  end

  @doc ~S"""
  Returns the first n bytes with the remainder of a binary.

  ##Example

  iex> Framer.split_binary("Hello World", 4)
  {"Hell", "o World"}

  iex> Framer.split_binary("Hello", 10)
  {"Hello", nil}
  """
  @spec split_binary(binary, pos_integer) :: {binary, nil | binary}
  def split_binary(binary, length_in_bytes) do
    if byte_size(binary) <= length_in_bytes do
      {binary, nil}
    else
      <<pack::binary-size(length_in_bytes), rest::binary>> = binary

      {pack, rest}
    end
  end
end
