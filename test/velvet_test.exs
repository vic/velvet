defmodule VelvetTest do
  use ExUnit.Case
  import Velvet.Sigils
  doctest Velvet

  describe "sexp" do
    test "is empty for empty program" do
      assert {:ok, []} = ~V//sexp
    end

    test "is list of single atom for program just containing it" do
      assert {:ok, [:hello]} = ~V/ :hello /sexp
    end

    test "is list of single identifier for program just containing it" do
      assert {:ok, [{:world, _, _}]} = ~V/ world /sexp
    end

    test "is list of identifiers for program without comma between them" do
      assert {:ok, [{:hello, _, _}, {:world, _, _}]} = ~V/ hello world /sexp
    end

    test "is keyword for program just containing it" do
      assert {:ok, [hello: :world]} = ~V/ hello: :world /sexp
    end

    test "is identifier of single bin operator +" do
      assert {:ok, [{:+, _, _}]} = ~V/ + /sexp
    end

    test "is identifier of dot operator ." do
      assert {:ok, [{:., _, _}]} = ~V/ . /sexp
    end

    test "is sexp of list operator for empty list program" do
      assert {:ok, [  [{:list, _, nil}]  ]} = ~V/ [ ] /sexp
    end

    test "brackets create list even without commas in it" do
      assert {:ok, [  [{:list, _, _}, 1, 2]  ]} = ~V/ [ 1 2 ] /sexp
    end
  end


end
