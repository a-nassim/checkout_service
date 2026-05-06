defmodule CheckoutServiceTest do
  use ExUnit.Case
  doctest CheckoutService

  test "greets the world" do
    assert CheckoutService.hello() == :world
  end
end
