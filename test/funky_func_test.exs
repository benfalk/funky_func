defmodule FunkyFuncTest do
  use ExUnit.Case
  doctest FunkyFunc

  defmodule Funk do
    import FunkyFunc

    package_fun :alert, fn -> "me when ready!" end
    package_fun :tell, fn who, what -> "#{who}, you've done #{what}!" end

    def is_quoted_fun(fun) when quoted_fun?(fun), do: true 
    def is_quoted_fun(_), do: false
  end

  test "#quoted_fun?/1" do
    refute FunkyFunc.quoted_fun?(&(&1))
    refute FunkyFunc.quoted_fun?(fn a -> a end)
    #refute FunkyFunc.quoted_fun?(:rofl)
    refute FunkyFunc.quoted_fun?({:a, :b, :c})
    assert FunkyFunc.quoted_fun?(quote do: &(&1))
    assert FunkyFunc.quoted_fun?(quote do: fn a -> a end)
    assert FunkyFunc.quoted_fun?(quote do: &String.downcase/1)
  end

  test "#quoted_fun?/1 in guard clause" do
    refute Funk.is_quoted_fun(&(&1))
    refute Funk.is_quoted_fun(fn a -> a end)
    refute Funk.is_quoted_fun(:rofl)
    refute Funk.is_quoted_fun({:a, :b, :c})
    assert Funk.is_quoted_fun(quote do: &(&1))
    assert Funk.is_quoted_fun(quote do: fn a -> a end)
  end

  test "#package_fun" do
    assert Funk.alert == "me when ready!"
    assert Funk.tell("Ben", "it") == "Ben, you've done it!"
  end
end
