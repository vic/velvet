defmodule VelvetTest do
  use ExUnit.Case
  import Velvet.Sigils
  doctest Velvet

  describe "parsing a sexp" do
    test "should be empty for empty program" do
      assert {:ok, []} = ~V//sexp
    end

    test "should be the atom for program only contains it" do
      assert {:ok, [:hello]} = ~V/ :hello /sexp
    end

    test "should be the quoted identifier for program only containing it" do
      assert {:ok, [{:world, _, _}]} = ~V/ world /sexp
    end

    test "should be a list of quoted identifiers for space separated program" do
      assert {:ok, [{:hello, _, _}, {:world, _, _}]} = ~V/ hello world /sexp
    end

    test "should be the tuple-2 of a keyword list" do
      assert {:ok, [hello: :world]} = ~V/ hello: :world /sexp
    end

    test "should parse a binary operator as an identifier" do
      assert {:ok, [{:+, _, _}]} = ~V/ + /sexp
    end

    test "should parse a dot as just another identifier" do
      assert {:ok, [{:., _, _}]} = ~V/ . /sexp
    end

    test "should parse the empty list to a sexp calling list with no args" do
      assert {:ok, [[{:list, _, nil}]]} = ~V/ [ ] /sexp
    end

    test "should parse a list with arguments" do
      assert {:ok, [[{:list, _, _}, 1, 2]]} = ~V/ [ 1 2 ] /sexp
    end

    test "should parse an empty tuple as a sexp calling tuple with no args" do
      assert {:ok, [[{:tuple, _, nil}]]} = ~V/ { } /sexp
    end

    test "should parse empty parens as an empty sexp" do
      assert {:ok, [[]]} = ~V/ () /sexp
    end

    test "should parse items without comma inside a paren expression" do
      assert {:ok, [[1, 2]]} = ~V/ (1 2) /sexp
    end

    test "should create an inner list sexp for keywords at the end of parent sexp" do
      assert {:ok, [[1, 2, [{:list, _, _}, {:foo, 3}, {:baz, 4}]]]} = ~V/ (1 2 foo: 3 baz: 4) /sexp
    end
  end
end
