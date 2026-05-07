defmodule CheckoutServiceTest do
  use ExUnit.Case

  @pricing_rules [
    # :bogo, "GR1"
    # :bulk_fixed, "SR1"
    # :bulk_fraction, "CF1"
  ]

  defp total(product_codes) do
    checkout =
      CheckoutService.new(@pricing_rules)

    checkout =
      Enum.reduce(product_codes, checkout, fn code, co ->
        CheckoutService.scan(co, code)
      end)

    CheckoutService.calculate(checkout).total
  end

  describe "acceptance tests" do
    test "GR1,SR1,GR1,GR1,CF1 → £22.45" do
      assert total(["GR1", "SR1", "GR1", "GR1", "CF1"]) == 22.45
    end

    test "GR1,GR1 → £3.11 (BOGO: pay for one)" do
      assert total(["GR1", "GR1"]) == 3.11
    end

    test "SR1,SR1,GR1,SR1 → £16.61 (bulk strawberries)" do
      assert total(["SR1", "SR1", "GR1", "SR1"]) == 16.61
    end

    test "GR1,CF1,SR1,CF1,CF1 → £30.57 (bulk coffee)" do
      assert total(["GR1", "CF1", "SR1", "CF1", "CF1"]) == 30.57
    end
  end

  describe "edge cases" do
    test "empty basket totals £0.00" do
      assert total([]) == 0.00
    end

    test "scan order does not affect the total" do
      assert total(["GR1", "SR1", "GR1", "GR1", "CF1"]) ==
               total(["CF1", "GR1", "GR1", "SR1", "GR1"])
    end

    test "checkout with no pricing rules applies full prices" do
      checkout = CheckoutService.new([])
      checkout = CheckoutService.scan(checkout, "GR1")
      checkout = CheckoutService.scan(checkout, "GR1")
      assert CheckoutService.calculate(checkout) == 6.22
    end
  end
end
