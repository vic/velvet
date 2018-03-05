defmodule Velvet.Tokens do

  @moduledoc """
  The velvet token compiler.

  The compiler uses this functions to turn velvet code from
  binary form into a velvet sexp.

  Velvet reuses Elixir tokenizer, and thus the literals
  have the same syntax, things like integers, strings,
  floats, are no different from elixir.

  However lists do have a difference: commas, semicolons and new lines
  are ignored by the reader, but replaced by a comma by the compiler.

  ```elixir
      # in Velvet this is a three element list
      [ foo bar baz ]

      # contrast this with elixir were it would have been parsed as:
      [ foo(bar(baz)) ]

      # the Velvet code will be compiled to this Elixir code:
      [ foo, bar, baz ]
  ```

  """

  @bracket_left_token {:"[", {0, 0, 0}}
  @bracket_right_token {:"]", {0, 0, 0}}
  @comma_token {:",", {0, 0, 0}}

  @elixir_ops [:"not in"] ++ ~W"
  @ . + - ! ^ not ~~ * / ++ -- .. <> in
  |> <<< >>> ~>> <<~ ~> <~ <~> <|>
  < > <= >= => == != =~ === !== =
  & && &&& and or | || ||| :: <- \\
  "a

  def string_to_sexp(string, opts) do
    with {:ok, tokens} <- string_to_tokens(string, opts) do
      tokens_to_sexp(tokens, opts)
    end
  end

  defp string_to_tokens(string, opts) do
    opts = [file: file, line: line] = file_and_line(opts)
    :elixir.string_to_tokens(to_charlist(string), line, file, opts)
  end

  defp tokens_to_quoted(tokens, opts) do
    opts = [file: file, line: _] = file_and_line(opts)
    :elixir.tokens_to_quoted(tokens, file, opts)
  end

  defp file_and_line(nil) do
    [file: "nofile", line: 1]
  end

  defp file_and_line(%{file: file, line: line}) do
    [file: file, line: line]
  end

  defp file_and_line(opts) when is_list(opts) do
    [file: file, line: line] = file_and_line(nil)
    file = Keyword.get(opts, :file, file)
    line = Keyword.get(opts, :line, line)
    [file: file, line: line]
  end

  defp tokens_to_sexp(tokens, opts) do
    tokens = collect(:sexp, tokens, [])
    tokens = Enum.reverse([@bracket_right_token | tokens])
    tokens = case tokens do
               [@comma_token | tokens] -> tokens
               tokens -> tokens
             end
    tokens = [@bracket_left_token] ++ tokens
    tokens_to_quoted(tokens, opts)
  end

  defp collect(:sexp = mode, [token = {:kw_identifier, _, _}, v_token | tokens], acc) do
    collect(mode, tokens, [v_token, token | acc])
  end

  defp collect(:sexp = mode, [{ignored, _, _} | tokens], acc)
  when ignored == :eol or ignored == :"," or ignored == :";" do
    collect(mode, tokens, acc)
  end

  defp collect(:sexp = mode, [{:., m} | tokens], acc) do
    token = {:identifier, m, :.}
    collect(mode, tokens, [token, @comma_token | acc])
  end

  @elixir_ops |> Enum.each(fn op ->
    defp collect(:sexp = mode, [{_, m, unquote(op) = id} | tokens], acc) do
      token = {:identifier, m, id}
      collect(mode, tokens, [token, @comma_token | acc])
    end
  end)

  defp collect(:sexp = mode, [token | tokens], acc) do
    collect(mode, tokens, [token, @comma_token | acc])
  end

  defp collect(mode, [token | tokens], acc) do
    collect(mode, tokens, [token | acc])
  end

  defp collect(_mode, [], acc), do: acc


end
