defmodule FunkyExample do
  import FunkyFunc

  defmacro __using__(_) do
    quote do
      import FunkyFunc, only: [package_funs: 1]
      import FunkyExample, only: [widget: 2]
    end
  end

  defmacro widget(name, opts) do
    funs = opts
    |> escape_fun_list
    |> Enum.filter(fn {_, v} -> escaped_fun?(v) end)
    |> Enum.map(fn {k, v} -> {:"#{name}_#{k}_action", v} end)

    quote do
      package_funs unquote(funs)
    end
  end
end
