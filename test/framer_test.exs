defmodule FramerTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest Framer

  describe "next_frame" do
    property "returns exactly first n-bytes and remainder from iodata" do
      check all(iodata <- StreamData.iodata(), size <- StreamData.positive_integer(), size > 0) do
        {frame, rem} = Framer.next_frame(iodata, size)

        assert is_list(frame)
        assert is_list(rem)

        assert IO.iodata_to_binary([frame, rem]) == IO.iodata_to_binary(iodata)
        assert IO.iodata_length(frame) in [0, size]
      end
    end
  end

  describe "next_frames" do
    property "returns ordered n-byte chunks and remainder from iodata" do
      check all(iodata <- StreamData.iodata(), size <- StreamData.positive_integer(), size > 0) do
        {frames, rem} = Framer.next_frames(iodata, size)

        assert is_list(frames)
        assert is_list(rem)

        assert IO.iodata_to_binary([frames, rem]) == IO.iodata_to_binary(iodata)
        assert Enum.all?(frames, fn frame -> IO.iodata_length(frame) == size end)
        assert IO.iodata_length(rem) < size
      end
    end
  end

  describe "resize/2" do
    property "returns ordered n-byte chunks and remainder from iodata as list" do
      check all(
              iodata <- StreamData.iodata(),
              size <- StreamData.positive_integer(),
              size > 0
            ) do
        result =
          iodata
          |> Framer.resize(size)

        all_elements_except_last = Enum.slice(result, 0..-2)
        last_element = Enum.slice(result, -1..1)

        assert Enum.all?(all_elements_except_last, fn e -> IO.iodata_length(e) == size end)
        assert IO.iodata_length(last_element) <= size
        assert IO.iodata_to_binary(result) == IO.iodata_to_binary(iodata)
      end
    end
  end

  describe "resize_stream/2" do
    property "resizes a stream in n-sized elements" do
      check all(
              iolist <- StreamData.list_of(StreamData.iodata()),
              size <- StreamData.positive_integer(),
              size > 0
            ) do
        result =
          iolist
          |> Framer.resize_stream(size)
          |> Enum.to_list()

        all_elements_except_last = Enum.slice(result, 0..-2)
        last_element = Enum.slice(result, -1..1)

        assert Enum.all?(all_elements_except_last, fn e -> IO.iodata_length(e) == size end)
        assert IO.iodata_length(last_element) <= size
        assert IO.iodata_to_binary(result) == IO.iodata_to_binary(iolist)
      end
    end
  end
end
