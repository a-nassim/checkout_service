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

  describe "remove/2" do
    test "decrements the quantity for an existing code" do
      {:ok, cart} = %Cart{} |> Cart.add("GR1") |> Cart.add("GR1") |> Cart.remove("GR1")
      assert cart.items == %{"GR1" => 1}
    end

    test "removing the last unit drops the code from the cart" do
      {:ok, cart} = %Cart{} |> Cart.add("GR1") |> Cart.remove("GR1")
      assert cart.items == %{}
    end

    test "removing a code that is not in the cart returns an error" do
      cart = Cart.add(%Cart{}, "GR1")
      assert Cart.remove(cart, "SR1") == {:error, :not_in_cart}
    end
  end

  describe "clear/1" do
    test "removes all tracked items" do
      cart = %Cart{} |> Cart.add("GR1") |> Cart.add("SR1") |> Cart.clear()
      assert cart.items == %{}
    end
  end
end
