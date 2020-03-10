defmodule FramerTest do
  use ExUnit.Case

  doctest Framer

  describe "resize_stream/2" do
    test "resizes a valid stream" do
      stream = ["abc ", [" ", ["ok"]], "t", "d", ["a"]]

      assert Framer.resize_stream(stream, 3) |> Enum.to_list() == [
               ["abc"],
               [" ", " ", "o"],
               ["k", "t", "d"],
               ["a"]
             ]
    end

    test "resize iodata" do
      stream = [?h, "el", ["l", [?o]]]

      assert Framer.resize_stream(stream, 2) |> Enum.to_list() == [
               ["h", "e"],
               ["l", "l"],
               ["o"]
             ]
    end

    test "slightly bigger stream" do
      data_file = "test/fixture.txt"

      data =
        File.stream!(data_file, [], 32)
        |> Framer.resize_stream(10)
        |> Enum.to_list()
        |> IO.iodata_to_binary()

      assert data == File.read!(data_file)
    end
  end

  describe "resize/2" do
    test "simple" do
      list = ["abcefg ", "ga", " ac", "d"]

      assert Framer.resize(list, 3) ==
               [["abc"], ["efg"], [" ", "ga"], [" ac"], ["d"]]
    end

    test "empty enum" do
      assert Framer.resize([], 3) == []
    end

    test "nested iodata" do
      list = [["a", "bc", ["d", ["e"]]]]

      assert Framer.resize(list, 3) == [["a", "bc"], ["d", "e"]]
    end
  end

  describe "next_frame" do
    test "simple" do
      assert Framer.next_frame(["abc"], 3) == {["abc"], []}
    end

    test "join smaller chunks" do
      assert Framer.next_frame(["ab", "c"], 3) == {["ab", "c"], []}
    end

    test "split larger chunks" do
      assert Framer.next_frame(["abcd", ["def"]], 3) == {["abc"], ["d", ["def"]]}
    end
  end

  describe "split_binary/2" do
    test "empty string" do
      assert Framer.split_binary("", 3) == {"", nil}
    end

    test "smaller" do
      assert Framer.split_binary("ab", 3) == {"ab", nil}
    end

    test "exact size" do
      assert Framer.split_binary("abc", 3) == {"abc", nil}
    end

    test "a bit larger" do
      assert Framer.split_binary("abc ", 3) == {"abc", " "}
    end
  end
end
