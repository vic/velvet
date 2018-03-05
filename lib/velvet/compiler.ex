defmodule Velvet.Compiler do

  def code_to_elixir_ast(code, opts \\ []) when is_binary(code) do
    with {:ok, sexp} <- Velvet.Tokens.string_to_sexp(code, opts) do
      Velvet.Sexp.expand(sexp, opts)
    end
  end

end
