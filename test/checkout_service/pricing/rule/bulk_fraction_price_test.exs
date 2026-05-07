defmodule CheckoutService.Pricing.Rule.BulkFractionPriceTest do
  use ExUnit.Case, async: true

  alias CheckoutService.Catalog.Product
  alias CheckoutService.Pricing.Discount
  alias CheckoutService.Pricing.Rule
  alias CheckoutService.Pricing.Rule.BulkFractionPrice

  @coffee %Product{code: "CF1", name: "Coffee", price: Money.new(:GBP, "11.23")}
  @green_tea %Product{code: "GR1", name: "Green tea", price: Money.new(:GBP, "3.11")}

  describe "new/3" do
    test "returns {:ok, rule} for valid fraction" do
      assert {:ok, %BulkFractionPrice{product_code: "CF1", threshold: 3}} =
               BulkFractionPrice.new("CF1", 3, {1, 3})
    end

    test "returns error when threshold is zero" do
      assert {:error, :invalid_threshold} = BulkFractionPrice.new("CF1", 0, {1, 3})
    end

    test "returns error when threshold is negative" do
      assert {:error, :invalid_threshold} = BulkFractionPrice.new("CF1", -1, {1, 3})
    end

    test "returns error when fraction elements are not integers" do
      assert {:error, :invalid_threshold} = BulkFractionPrice.new("CF1", 3, {1.0, 3})
      assert {:error, :invalid_threshold} = BulkFractionPrice.new("CF1", 3, {"1", 3})
    end

    test "returns error when fraction is zero" do
      assert {:error, :invalid_fraction} = BulkFractionPrice.new("CF1", 3, {0, 1})
    end

    test "returns error when fraction is one" do
      assert {:error, :invalid_fraction} = BulkFractionPrice.new("CF1", 3, {1, 1})
    end

    test "returns error when fraction exceeds one" do
      assert {:error, :invalid_fraction} = BulkFractionPrice.new("CF1", 3, {3, 2})
    end

    test "returns error when denominator is zero" do
      assert {:error, :invalid_fraction} = BulkFractionPrice.new("CF1", 3, {1, 0})
    end
  end

  describe "new!/3" do
    test "returns the rule when valid" do
      assert %BulkFractionPrice{} = BulkFractionPrice.new!("CF1", 3, {1, 3})
    end

    test "raises when threshold is invalid" do
      assert_raise ArgumentError, ~r/threshold must be a positive integer/, fn ->
        BulkFractionPrice.new!("CF1", 0, {1, 3})
      end
    end

    test "raises when fraction is invalid" do
      assert_raise ArgumentError, ~r/fraction must be between 0 and 1 exclusive/, fn ->
        BulkFractionPrice.new!("CF1", 3, {0, 1})
      end
    end
  end

  describe "apply/3" do
    setup do
      # CF1: 3+ → pay 2/3 (1/3 discount)
      {:ok, rule: BulkFractionPrice.new!("CF1", 3, {2, 3})}
    end

    test "does not apply below threshold", %{rule: rule} do
      assert Rule.apply(rule, @coffee, 2) == nil
    end

    test "applies at threshold — 3 items", %{rule: rule} do
      discount = Rule.apply(rule, @coffee, 3)
      assert %Discount{amount: amount} = discount
      # £11.23 * (1 - 2/3) * 3 = £11.23 * 1/3 * 3 = £11.23
      assert Money.equal?(amount, Money.new(:GBP, "11.23"))
    end

    test "applies above threshold — 5 items", %{rule: rule} do
      discount = Rule.apply(rule, @coffee, 5)
      assert %Discount{amount: amount} = discount
      # £11.23 * 1/3 * 5 = £18.72
      assert Money.equal?(
               amount |> Money.round(),
               Money.new(:GBP, "18.72")
             )
    end

    test "discount carries the rule and product", %{rule: rule} do
      product = @coffee
      discount = Rule.apply(rule, product, 3)
      assert %Discount{rule: ^rule, product: ^product} = discount
    end

    test "does not apply to a different product", %{rule: rule} do
      assert Rule.apply(rule, @green_tea, 3) == nil
    end
  end

  describe "different fractions" do
    test "50% discount — pay 1/2" do
      rule = BulkFractionPrice.new!("CF1", 2, {1, 2})
      discount = Rule.apply(rule, @coffee, 2)
      # £11.23 * (1 - 1/2) * 2 = £11.23
      assert Money.equal?(discount.amount, Money.new(:GBP, "11.23"))
    end

    test "10% discount — pay 9/10" do
      rule = BulkFractionPrice.new!("CF1", 2, {9, 10})
      discount = Rule.apply(rule, @coffee, 2)
      # £11.23 * 1/10 * 2 = £2.246
      assert Money.equal?(discount.amount, Money.new(:GBP, "2.246"))
    end
  end
end
