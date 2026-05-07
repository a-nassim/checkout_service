defmodule CheckoutService.Pricing.CalculatorTest do
  use ExUnit.Case, async: true

  alias CheckoutService.Catalog
  alias CheckoutService.Checkout.Cart
  alias CheckoutService.Checkout.LineItem
  alias CheckoutService.Pricing.Calculator

  defp money(amount), do: Money.new(:GBP, amount)

  defp cart(codes) do
    Enum.reduce(codes, %Cart{}, fn code, c -> Cart.add(c, code) end)
  end

  describe "line items" do
    test "empty cart produces no line items" do
      receipt = Calculator.calculate(%Cart{}, [], Catalog.default())
      assert receipt.line_items == []
    end

    test "single product produces one line item" do
      receipt = Calculator.calculate(cart(["GR1"]), [], Catalog.default())
      assert [%LineItem{quantity: 1, line_total: line_total}] = receipt.line_items
      assert Money.equal?(line_total, money("3.11"))
    end

    test "scanning the same product twice produces one line item with quantity 2" do
      receipt = Calculator.calculate(cart(["GR1", "GR1"]), [], Catalog.default())
      assert [%LineItem{quantity: 2, line_total: line_total}] = receipt.line_items
      assert Money.equal?(line_total, money("6.22"))
    end

    test "different products produce one line item each" do
      receipt = Calculator.calculate(cart(["GR1", "SR1"]), [], Catalog.default())
      assert length(receipt.line_items) == 2

      codes = Enum.map(receipt.line_items, & &1.product.code)
      assert "GR1" in codes
      assert "SR1" in codes
    end

    test "line item carries the resolved product" do
      receipt = Calculator.calculate(cart(["GR1"]), [], Catalog.default())
      assert [%LineItem{product: product}] = receipt.line_items
      assert product.code == "GR1"
      assert product.name == "Green tea"
    end

    test "line_total is price times quantity" do
      receipt = Calculator.calculate(cart(["SR1", "SR1", "SR1"]), [], Catalog.default())
      assert [%LineItem{quantity: 3, line_total: line_total}] = receipt.line_items
      assert Money.equal?(line_total, money("15.00"))
    end
  end

  describe "subtotal" do
    test "empty cart subtotal is zero" do
      receipt = Calculator.calculate(%Cart{}, [], Catalog.default())
      assert Money.equal?(receipt.subtotal, money("0"))
    end

    test "subtotal is the sum of all line totals" do
      # GR1 £3.11 + SR1 £5.00 = £8.11
      receipt = Calculator.calculate(cart(["GR1", "SR1"]), [], Catalog.default())
      assert Money.equal?(receipt.subtotal, money("8.11"))
    end
  end
end
