defmodule Framer do
  @moduledoc ~S"""
  Module contains helper functions to resize iodata streams and lists.

  The two main functions are:
  - `resize_stream/2` for resizing an iodata stream
  - `resize/2` for resizing iodata

  ## Examples

  Resizing a iodata stream:

      iex> stream = ["The brown", " fox", ["that ", "jumped"], " up."]
      iex> Framer.resize_stream(stream, 5) |> Enum.to_list()
      [["The b"], ["rown", " "], ["fox", "th"], ["at ", "ju"], ["mped", " "], ["up."]]

  Resizing iodata:

      iex> enum = ["Hello ", "World"]
      iex> Framer.resize(enum, 4)
      [["Hell"], ["o ", "Wo"], ["rld"]]
  """

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
  @spec resize_stream(Enumerable.t(), pos_integer) :: Enumerable.t()
  def resize_stream(iodata, frame_size) do
    iodata
    |> Stream.concat([:finito])
    |> Stream.transform(
      fn -> [] end,
      fn
        :finito, acc -> {[acc], []}
        el, acc -> next_frames([acc, el], frame_size)
      end,
      fn _ -> :ok end
    )
  end

  @doc ~S"""
  Resizes `iodata` into a new `iolist` with elements of size `frame_size`.

  Returns a new iolist.

  ## Example

      iex> iodata = [?h, "el", ["l", [?o]], "world"]
      iex> Framer.resize(iodata, 3)
      [[?h, "el"], ["l", ?o, "w"], ["orl"], ["d"]]
  """
  @spec resize(iodata, pos_integer) :: iolist
  def resize(iodata, frame_size) do
    case iodata |> next_frames(frame_size) do
      {[], rem} -> [rem]
      {frames, []} -> frames
      {frames, rem} -> frames ++ [rem]
    end
  end

  @doc ~S"""
  Similar to `resize2` except that it returns a tuple with the frames and
  remainder

  ## Example

      iex> iodata = [?h, "el", ["l", [?o]], "world"]
      iex> Framer.next_frames(iodata, 3)
      {[[?h, "el"], ["l", ?o, "w"], ["orl"]], ["d"]}
  """
  @spec next_frames(iodata, pos_integer) :: {iolist, iodata}
  def next_frames(iodata, frame_size) do
    next_frames(iodata, [], frame_size)
  end

  defp next_frames(iodata, acc, frame_size) do
    case next_frame(iodata, frame_size) do
      {[], rem} -> {acc |> Enum.reverse(), rem}
      {frame, rem} -> next_frames(rem, [frame | acc], frame_size)
    end
  end

  @doc ~S"""
  Returns a tuple containing the first frame of `frame_size` taken off
  iodata and the reminder of the list.

  ## Example

      iex> iodata = [?h, "el", ["l", [?o]], "world"]
      iex> Framer.next_frame(iodata, 3)
      {[?h, "el"], [["l", [?o]], "world"]}

  When the whole iodata fits into a frame, return the io list with an empty
  remainder.

      iex> iodata = ["h", "ello"]
      iex> Framer.next_frame(iodata, 10)
      {[], ["h", "ello"]}
  """
  @spec next_frame(iodata, pos_integer) :: {[any], iodata}
  def next_frame(iodata, frame_size) when is_binary(iodata), do: next_frame([iodata], frame_size)

  def next_frame(iodata, frame_size) do
    {frame, rem} = next_frame(iodata, [], frame_size)

    {frame |> Enum.reverse(), rem}
  end

  defp next_frame(iodata, leftover, frame_size)

  defp next_frame(iodata, leftover, frame_size) when is_binary(iodata),
    do: next_frame([iodata], leftover, frame_size)

  defp next_frame([], leftover, _), do: {[], leftover |> Enum.reverse()}

  defp next_frame([element | rest], leftover, frame_size) when is_list(element) do
    case next_frame(element, leftover, frame_size) do
      {[], leftover} -> next_frame(rest, leftover |> Enum.reverse(), frame_size)
      {frame, sub_rest} -> {frame, [sub_rest, rest]}
    end
  end

  defp next_frame([element | rest], leftover, frame_size) do
    leftover_size = IO.iodata_length(leftover)
    total_size = leftover_size + IO.iodata_length([element])

    cond do
      total_size == frame_size ->
        {[element | leftover], rest}

      total_size < frame_size ->
        next_frame(rest, [element | leftover], frame_size)

      total_size > frame_size ->
        chunk_size = frame_size - leftover_size
        <<chunk::binary-size(chunk_size), rem::binary>> = IO.iodata_to_binary([element])
        {[chunk | leftover], [rem | rest]}
    end
  end
end
