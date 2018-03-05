defmodule Velvet.Sigils do

  defmacro sigil_V({_, _, [code]}, []) do
    Velvet.Compiler.code_to_elixir_ast(code, __CALLER__)
  end

  defmacro sigil_V({_, _, [code]}, 'sexp') do
    Velvet.Tokens.string_to_sexp(code, __CALLER__)
    |> Macro.escape
  end

  defmacro sigil_V({_, _, [code]}, 'elixir-ast') do
    Velvet.Compiler.code_to_elixir_ast(code, __CALLER__)
    |> Macro.escape
  end

end
