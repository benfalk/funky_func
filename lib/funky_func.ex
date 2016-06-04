defmodule FunkyFunc do
  @moduledoc """
  Inspired by the desire to create a dynamic DSL in which
  you can use anonymous functions to help drive the functionality
  of your library.
  """

  @type escaped_fun :: {:escaped_fun, {String.t, non_neg_integer}}

  @doc """
  This should primarily be used as a guard clause for a macro to
  determine if an input is the ast of an anon function or in the
  area of a macro before quoting has happened.
  """
  defmacro quoted_fun?(what) do
    quote do
      is_tuple(unquote(what))
      and tuple_size(unquote(what)) == 3
      and elem(unquote(what), 0) in [:fn, :&]
      and is_list(elem(unquote(what), 1))
      and is_list(elem(unquote(what), 2))
    end
  end

  @doc """
  Determines if the supplied value is an anon function that was
  escaped by this module.  Can also be used in a guard clause
  """
  defmacro escaped_fun?(what) do
    quote do
      is_tuple(unquote(what))
      and tuple_size(unquote(what)) == 2
      and elem(unquote(what), 0) == :escaped_fun
      and is_tuple(elem(unquote(what), 1))
      and tuple_size(elem(unquote(what), 1)) == 2
      and is_binary(elem(elem(unquote(what), 1), 0))
      and is_integer(elem(elem(unquote(what), 1), 1))
    end
  end

  @doc """
  Given a name and either an anon or escaped function this will
  create a function on the module with the name supplied that
  matches the arity and delegates to it.

  iex> defmodule Test do
  ...>   require FunkyFunc
  ...>   FunkyFunc.package_fun :add, &(&1 + &2)
  ...> end
  ...> Test.add(4, 3)
  7
  """
  defmacro package_fun(name, expr) when escaped_fun?(expr) do
    do_package(name, expr)
  end
  defmacro package_fun(name, expr) when quoted_fun?(expr) do
    do_package(name, do_escape(expr))
  end
  defmacro package_fun(name, expr) do
    raise "UNEXPECTED EXPRESSION FOR [#{name}]: #{inspect expr}"
  end

  @doc """
  """
  defmacro package_funs(list) when is_list(list) do
    list
    |> Enum.map(fn {name, expr} -> def_string(name, expr) end)
    |> Enum.join("\n")
    |> Code.string_to_quoted!
  end

  @doc """
  Use this to escape an anon function if you want to expand it later
  with something like the `package_fun` macro.  Note that no scope
  follows this and as such will fail if you attempt to use it this
  way.
  """
  def escape_fun(expr) when quoted_fun?(expr) do
    escaped = do_escape(expr)

    quote do
      unquote(escaped)
    end
  end

  @doc """
  Useful when you have a DSL in which keys may have anon functions
  on them.  This walks the keyword list and will escape them for you.
  """
  def escape_fun_list(list) when is_list(list) do
    new_list =
      for {name, expr} <- list do
        if quoted_fun?(expr) do
          {name, do_escape(expr)}
        else
          {name, expr}
        end
      end

    quote do
      unquote(new_list)
    end
  end

  defp do_package(name, expr) when escaped_fun?(expr) do
    def_string(name, expr) |> Code.string_to_quoted!
  end

  defp do_escape(expr) do
    {:escaped_fun, {Macro.to_string(expr), arity(expr)}}
  end

  defp def_string(name, {:escaped_fun, {func_str, arity}}) do
    vars = 
      :lists.seq(1, arity)
      |> Enum.map(&("var#{&1}"))
      |> Enum.join(", ")

    """
    def #{name}(#{vars}), do: apply(#{func_str}, [#{vars}])
    """
  end

  defp arity(expr) do
    {func, []} = Code.eval_quoted(expr)
    {:arity, arity} = :erlang.fun_info(func, :arity)
    arity
  end
end
