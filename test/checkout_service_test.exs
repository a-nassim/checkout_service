defmodule CheckoutServiceTest do
  use ExUnit.Case

  alias CheckoutService.Pricing
  # Pricing rules — shape TBD when CheckoutService.Pricing.Rule is defined.
  # For now an empty list exercises the interface without any discounts.
  @pricing_rules [
    Pricing.Rule.BuyXGetYFree.new!("GR1", 1, 1),
    Pricing.Rule.BulkUnitPrice.new!("SR1", 3, Money.new(:GBP, "4.50"), Money.new(:GBP, "5.00"))
    # :bulk_fraction, "CF1"
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
      assert total(["GR1", "CF1", "SR1", "CF1", "CF1"]) == money("30.57")
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
  end
end
