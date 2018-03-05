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

  @round_left :"("
  @square_left :"["
  @curly_left :"{"
  @curly_right :"}"
  @square_right :"]"
  @round_right :")"

  @round_parens {@round_left, @round_right}

  @left_square_token {@square_left, {0, 0, 0}}
  @right_square_token {@square_right, {0, 0, 0}}
  @comma_token {:",", {0, 0, 0}}
  @list_token {:identifier, {0, 0, nil}, :list}
  @tuple_token {:identifier, {0, 0, nil}, :tuple}
  @white_space [:",", :";", :eol]

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

  defp file_and_line(%{file: file, line: line}) do
    [file: file, line: line]
  end

  defp file_and_line(env: env) do
    file_and_line(env)
  end

  defp file_and_line(opts) when is_list(opts) do
    file = Keyword.get(opts, :file, "nofile")
    line = Keyword.get(opts, :line, 1)
    [file: file, line: line]
  end

  defp file_and_line(_) do
    [file: "nofile", line: 1]
  end

  defp tokens_to_sexp(tokens, opts) do
    tokens = collect({:sexp, []}, tokens, [])
    tokens = Enum.reverse([@right_square_token | tokens])

    tokens =
      case tokens do
        [@comma_token | tokens] -> tokens
        tokens -> tokens
      end

    tokens =
      ([@left_square_token] ++ tokens)
      |> IO.inspect()

    tokens_to_quoted(tokens, opts)
  end

  defp collect({:sexp, _} = ctx, tokens, [x, @comma_token, dot = {:., _} | acc]) do
    collect(ctx, tokens, [x, dot | acc])
  end

  defp collect({:sexp, _} = ctx, tokens, [first, @comma_token, @left_square_token | acc]) do
    collect(ctx, tokens, [first, @left_square_token | acc])
  end

  defp collect({:sexp, [@round_parens | c]}, tokens, [
         kv,
         @comma_token,
         ki = {:kw_identifier, _, _} | acc
       ]) do
    ctx = {:sexp, [:kw, @round_parens | c]}
    collect(ctx, tokens, [kv, ki, @comma_token, @list_token, @left_square_token | acc])
  end

  defp collect({:sexp, _} = ctx, tokens, [kv, @comma_token, ki = {:kw_identifier, _, _} | acc]) do
    collect(ctx, tokens, [kv, ki | acc])
  end

  defp collect({:sexp, c}, [{@round_left, _} | tokens], acc) do
    ctx = {:sexp, [{@round_left, @round_right} | c]}
    collect(ctx, tokens, [@left_square_token | acc])
  end

  defp collect({:sexp, c}, [{@square_left, _} | tokens], acc) do
    ctx = {:sexp, [{@square_left, @square_right} | c]}
    collect(ctx, tokens, [@list_token, @left_square_token | acc])
  end

  defp collect({:sexp, c}, [{@curly_left, _} | tokens], acc) do
    ctx = {:sexp, [{@curly_left, @curly_right} | c]}
    collect(ctx, tokens, [@tuple_token, @left_square_token | acc])
  end

  defp collect({:sexp, [:kw, {_l, r} | c]}, [{close, _} | tokens], acc) when r == close do
    ctx = {:sexp, c}
    collect(ctx, tokens, [@right_square_token, @right_square_token | acc])
  end

  defp collect({:sexp, [{_l, r} | c]}, [{close, _} | tokens], acc) when r == close do
    ctx = {:sexp, c}
    collect(ctx, tokens, [@right_square_token | acc])
  end

  @white_space
  |> Enum.each(fn ws ->
    defp collect({:sexp, _} = ctx, [{unquote(ws), _, _} | tokens], acc) do
      collect(ctx, tokens, acc)
    end
  end)

  defp collect({:sexp, [@round_parens | _]} = ctx, [{:., m} | tokens], [@left_square_token | _] = acc) do
    token = {:identifier, m, :.}
    collect(ctx, tokens, [token | acc])
  end

  defp collect({:sexp, _} = ctx, [token = {:., _} | tokens], acc) do
    collect(ctx, tokens, [token | acc])
  end

  @elixir_ops
  |> Enum.each(fn op ->
    defp collect({:sexp, _} = ctx, [{_, m, unquote(op) = id} | tokens], acc) do
      token = {:identifier, m, id}
      collect(ctx, tokens, [token, @comma_token | acc])
    end
  end)

  defp collect({:sexp, _} = ctx, [token | tokens], acc) do
    collect(ctx, tokens, [token, @comma_token | acc])
  end

  defp collect({:sexp, []}, [], acc), do: acc
end
