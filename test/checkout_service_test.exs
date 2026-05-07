defmodule CheckoutServiceTest do
  use ExUnit.Case

  alias CheckoutService.Pricing

  @pricing_rules [
    Pricing.Rule.BuyXGetYFree.new!("GR1", 1, 1),
    Pricing.Rule.BulkUnitPrice.new!("SR1", 3, Money.new(:GBP, "4.50"), Money.new(:GBP, "5.00")),
    Pricing.Rule.BulkFractionPrice.new!("CF1", 3, {2, 3})
  ]

  defp money(amount), do: Money.new(:GBP, amount)

  defp total(product_codes) do
    checkout = CheckoutService.new(@pricing_rules)

    checkout =
      Enum.reduce(product_codes, checkout, fn code, co ->
        CheckoutService.scan!(co, code)
      end)

    CheckoutService.calculate(checkout).total
  end

  describe "acceptance tests" do
    test "GR1,SR1,GR1,GR1,CF1 → £22.45" do
      assert total(["GR1", "SR1", "GR1", "GR1", "CF1"]) == money("22.45")
    end

    test "GR1,GR1 → £3.11 (BOGO: pay for one)" do
      assert total(["GR1", "GR1"]) == money("3.11")
    end

    test "SR1,SR1,GR1,SR1 → £16.61 (bulk strawberries)" do
      assert total(["SR1", "SR1", "GR1", "SR1"]) == money("16.61")
    end

    test "GR1,CF1,SR1,CF1,CF1 → £30.57 (bulk coffee)" do
      assert Money.equal?(total(["GR1", "CF1", "SR1", "CF1", "CF1"]), money("30.57"))
    end
  end

  describe "edge cases" do
    test "empty basket totals £0.00" do
      assert Money.equal?(total([]), money("0.00"))
    end

    test "scan order does not affect the total" do
      assert total(["GR1", "SR1", "GR1", "GR1", "CF1"]) ==
               total(["CF1", "GR1", "GR1", "SR1", "GR1"])
    end

    test "no pricing rules applies full prices" do
      receipt =
        CheckoutService.new([])
        |> CheckoutService.scan!("GR1")
        |> CheckoutService.scan!("GR1")
        |> CheckoutService.calculate()

      assert receipt.total == money("6.22")
      assert receipt.discounts == []
    end

    test "scan/2 returns error for unknown product code" do
      checkout = CheckoutService.new([])
      assert {:error, :unknown_product} = CheckoutService.scan(checkout, "UNKNOWN")
    end

    test "scan!/2 raises for unknown product code" do
      checkout = CheckoutService.new([])
      assert_raise ArgumentError, fn -> CheckoutService.scan!(checkout, "UNKNOWN") end
    end

    test "remove/2 removes one scanned product and recalculates discounts" do
      checkout =
        CheckoutService.new(@pricing_rules)
        |> CheckoutService.scan!("GR1")
        |> CheckoutService.scan!("GR1")
        |> CheckoutService.scan!("GR1")
        |> CheckoutService.remove!("GR1")

      receipt = CheckoutService.calculate(checkout)

      assert receipt.total == money("3.11")
      assert [%{quantity: 2}] = receipt.line_items
    end

    test "remove/2 returns error when the product was not scanned" do
      checkout =
        CheckoutService.new([])
        |> CheckoutService.scan!("GR1")

      assert CheckoutService.remove(checkout, "SR1") == {:error, :not_in_cart}
    end

    test "remove/2 returns not in cart for unknown product code" do
      checkout = CheckoutService.new([])
      assert CheckoutService.remove(checkout, "UNKNOWN") == {:error, :not_in_cart}
    end

    test "remove!/2 raises when product is not in the cart" do
      checkout = CheckoutService.new([])
      assert_raise ArgumentError, fn -> CheckoutService.remove!(checkout, "UNKNOWN") end
    end

    test "clear/1 empties the checkout cart" do
      receipt =
        CheckoutService.new(@pricing_rules)
        |> CheckoutService.scan!("GR1")
        |> CheckoutService.scan!("SR1")
        |> CheckoutService.clear()
        |> CheckoutService.calculate()

      assert receipt.total == money("0.00")
      assert receipt.line_items == []
      assert receipt.discounts == []
    end
  end
end
