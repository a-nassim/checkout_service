defmodule CheckoutService.Checkout.CartTest do
  use ExUnit.Case, async: true

  alias CheckoutService.Checkout.Cart

  describe "add/2" do
    test "first scan of a code sets quantity to 1" do
      cart = Cart.add(%Cart{}, "GR1")
      assert cart.items == %{"GR1" => 1}
    end

    test "scanning the same code twice increments the quantity" do
      cart = %Cart{} |> Cart.add("GR1") |> Cart.add("GR1")
      assert cart.items == %{"GR1" => 2}
    end

    test "scanning different codes tracks them independently" do
      cart = %Cart{} |> Cart.add("GR1") |> Cart.add("SR1") |> Cart.add("GR1")
      assert cart.items == %{"GR1" => 2, "SR1" => 1}
    end
  end
end
