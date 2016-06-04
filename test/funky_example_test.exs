defmodule FunkyExampleTest do
  use ExUnit.Case

  defmodule FunkyFactory do
    use FunkyExample

    widget :foo, 
           delete: fn w -> "delete foo #{w}" end,
           create: fn w -> "create foo #{w}" end,
           merge:  &("#{&1}==>#{&2}")
  end

  test "FunkyFactory" do
    assert FunkyFactory.foo_delete_action("bar") == "delete foo bar"
    assert FunkyFactory.foo_create_action("baz") == "create foo baz"
    assert FunkyFactory.foo_merge_action("bar", "baz") == "bar==>baz"
  end
end
