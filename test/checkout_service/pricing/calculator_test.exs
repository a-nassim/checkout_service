defmodule CheckoutService.Pricing.CalculatorTest do
  use ExUnit.Case, async: true

  alias CheckoutService.Catalog
  alias CheckoutService.Catalog.Product
  alias CheckoutService.Checkout.Cart
  alias CheckoutService.Checkout.LineItem
  alias CheckoutService.Pricing
  alias CheckoutService.Pricing.Calculator
  alias CheckoutService.Pricing.Rule.{BulkFractionPrice, BulkUnitPrice, BuyXGetYFree}

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

  describe "discounts" do
    setup do
      rules = [
        BuyXGetYFree.new!("GR1", 1, 1),
        BulkUnitPrice.new!("SR1", 3, Money.new(:GBP, "4.50"), Money.new(:GBP, "5.00")),
        BulkFractionPrice.new!("CF1", 3, {2, 3})
      ]

      {:ok, rules: rules}
    end

    test "no discounts when no rules match", %{rules: rules} do
      receipt = Calculator.calculate(cart(["GR1"]), rules, Catalog.default())
      assert receipt.discounts == []
    end

    test "BOGO discount on green tea", %{rules: rules} do
      receipt = Calculator.calculate(cart(["GR1", "GR1"]), rules, Catalog.default())
      assert [%Pricing.Discount{rule: rule, product: product, amount: amount}] = receipt.discounts
      assert %Pricing.Rule.BuyXGetYFree{product_code: "GR1", buy_amount: 1, free_amount: 1} = rule
      assert product.code == "GR1"
      assert Money.equal?(amount, money("3.11"))
      assert Money.equal?(receipt.total, money("3.11"))
    end

    test "bulk price discount on strawberries", %{rules: rules} do
      receipt = Calculator.calculate(cart(["SR1", "SR1", "SR1"]), rules, Catalog.default())
      assert [%Pricing.Discount{rule: rule, product: product, amount: amount}] = receipt.discounts
      assert %Pricing.Rule.BulkUnitPrice{product_code: "SR1", threshold: 3} = rule
      assert product.code == "SR1"
      # (£5.00 - £4.50) * 3 = £1.50
      assert Money.equal?(amount, money("1.50"))
      assert Money.equal?(receipt.total, money("13.50"))
    end

    test "percentage discount on coffee", %{rules: rules} do
      receipt = Calculator.calculate(cart(["CF1", "CF1", "CF1"]), rules, Catalog.default())
      assert [%Pricing.Discount{rule: rule, product: product, amount: amount}] = receipt.discounts
      assert %Pricing.Rule.BulkFractionPrice{product_code: "CF1", threshold: 3} = rule
      assert product.code == "CF1"
      # £11.23 * (1 - 2/3) * 3 = £11.23
      assert Money.equal?(amount, money("11.23"))
      assert Money.equal?(receipt.total, money("22.46"))
    end

    test "multiple discounts on different products", %{rules: rules} do
      receipt =
        Calculator.calculate(cart(["GR1", "GR1", "SR1", "SR1", "SR1"]), rules, Catalog.default())

      assert length(receipt.discounts) == 2
      codes = Enum.map(receipt.discounts, & &1.product.code)
      assert "GR1" in codes
      assert "SR1" in codes
    end

    test "discounts are applied in order", %{rules: rules} do
      # With rules in this order, BOGO fires first for GR1
      receipt = Calculator.calculate(cart(["GR1", "GR1"]), rules, Catalog.default())
      assert length(receipt.discounts) == 1
      assert %Pricing.Rule.BuyXGetYFree{} = Enum.at(receipt.discounts, 0).rule
    end

    test "total is rounded to the currency precision" do
      {:ok, catalog} =
        Catalog.new(:GBP, [
          %Product{code: "TS1", name: "Test tea", price: money("10.00")}
        ])

      rules = [
        PercentageDiscount.new!("TS1", 2, {2, 3})
      ]

      receipt = Calculator.calculate(cart(["TS1", "TS1"]), rules, catalog)

      assert Money.equal?(receipt.subtotal, money("20.00"))
      assert Money.equal?(receipt.total, money("13.33"))
    end
  end
end
