defmodule CheckoutService.Pricing.Rule.BulkUnitPriceTest do
  use ExUnit.Case, async: true

  alias CheckoutService.Catalog.Product
  alias CheckoutService.Pricing.Discount
  alias CheckoutService.Pricing.Rule
  alias CheckoutService.Pricing.Rule.BulkUnitPrice

  @strawberry %Product{code: "SR1", name: "Strawberries", price: Money.new(:GBP, "5.00")}
  @green_tea %Product{code: "GR1", name: "Green tea", price: Money.new(:GBP, "3.11")}

  describe "new/4" do
    test "returns {:ok, rule} when bulk price is less than catalog price" do
      assert {:ok, %BulkUnitPrice{product_code: "SR1", threshold: 3}} =
               BulkUnitPrice.new("SR1", 3, Money.new(:GBP, "4.50"), Money.new(:GBP, "5.00"))
    end

    test "returns error when threshold is zero" do
      assert {:error, :invalid_threshold} =
               BulkUnitPrice.new("SR1", 0, Money.new(:GBP, "4.50"), Money.new(:GBP, "5.00"))
    end

    test "returns error when threshold is negative" do
      assert {:error, :invalid_threshold} =
               BulkUnitPrice.new("SR1", -1, Money.new(:GBP, "4.50"), Money.new(:GBP, "5.00"))
    end

    test "returns error when threshold is not an integer" do
      assert {:error, :invalid_threshold} =
               BulkUnitPrice.new("SR1", 1.5, Money.new(:GBP, "4.50"), Money.new(:GBP, "5.00"))
    end

    test "returns error when bulk price equals catalog price" do
      assert {:error, :price_not_discounted} =
               BulkUnitPrice.new("SR1", 3, Money.new(:GBP, "5.00"), Money.new(:GBP, "5.00"))
    end

    test "returns error when bulk price exceeds catalog price" do
      assert {:error, :price_not_discounted} =
               BulkUnitPrice.new("SR1", 3, Money.new(:GBP, "6.00"), Money.new(:GBP, "5.00"))
    end
  end

  describe "new!/4" do
    test "returns the rule when valid" do
      assert %BulkUnitPrice{} =
               BulkUnitPrice.new!("SR1", 3, Money.new(:GBP, "4.50"), Money.new(:GBP, "5.00"))
    end

    test "raises when threshold is invalid" do
      assert_raise ArgumentError, ~r/threshold must be a positive integer/, fn ->
        BulkUnitPrice.new!("SR1", 0, Money.new(:GBP, "4.50"), Money.new(:GBP, "5.00"))
      end
    end

    test "raises when bulk price is not discounted" do
      assert_raise ArgumentError, ~r/must be less than catalog price/, fn ->
        BulkUnitPrice.new!("SR1", 3, Money.new(:GBP, "5.00"), Money.new(:GBP, "5.00"))
      end
    end
  end

  describe "apply/3" do
    setup do
      {:ok,
       rule: %BulkUnitPrice{product_code: "SR1", threshold: 3, price: Money.new(:GBP, "4.50")}}
    end

    test "does not apply below threshold", %{rule: rule} do
      assert Rule.apply(rule, @strawberry, 2) == nil
    end

    test "applies at threshold — 3 items", %{rule: rule} do
      discount = Rule.apply(rule, @strawberry, 3)
      assert %Discount{amount: amount} = discount
      # (£5.00 - £4.50) * 3 = £1.50
      assert Money.equal?(amount, Money.new(:GBP, "1.50"))
    end

    test "applies above threshold — 5 items", %{rule: rule} do
      discount = Rule.apply(rule, @strawberry, 5)
      assert %Discount{amount: amount} = discount
      # (£5.00 - £4.50) * 5 = £2.50
      assert Money.equal?(amount, Money.new(:GBP, "2.50"))
    end

    test "discount carries the rule and product", %{rule: rule} do
      product = @strawberry
      discount = Rule.apply(rule, product, 3)
      assert %Discount{rule: ^rule, product: ^product} = discount
    end

    test "does not apply to a different product", %{rule: rule} do
      assert Rule.apply(rule, @green_tea, 3) == nil
    end
  end
end
