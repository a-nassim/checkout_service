defmodule CheckoutService.Pricing.Rule.BuyXGetYFreeTest do
  use ExUnit.Case, async: true

  alias CheckoutService.Catalog.Product
  alias CheckoutService.Pricing.Discount
  alias CheckoutService.Pricing.Rule
  alias CheckoutService.Pricing.Rule.BuyXGetYFree

  @green_tea %Product{code: "GR1", name: "Green tea", price: Money.new(:GBP, "3.11")}
  @strawberry %Product{code: "SR1", name: "Strawberries", price: Money.new(:GBP, "5.00")}

  defp bogo(code), do: BuyXGetYFree.new!(code, 1, 1)

  describe "new/3" do
    test "returns {:ok, rule} for valid amounts" do
      assert {:ok, %BuyXGetYFree{product_code: "GR1", buy_amount: 1, free_amount: 1}} =
               BuyXGetYFree.new("GR1", 1, 1)
    end

    test "returns error when buy_amount is zero" do
      assert {:error, :invalid_amounts} = BuyXGetYFree.new("GR1", 0, 1)
    end

    test "returns error when free_amount is zero" do
      assert {:error, :invalid_amounts} = BuyXGetYFree.new("GR1", 1, 0)
    end

    test "returns error when buy_amount is negative" do
      assert {:error, :invalid_amounts} = BuyXGetYFree.new("GR1", -1, 1)
    end

    test "returns error when amounts are not integers" do
      assert {:error, :invalid_amounts} = BuyXGetYFree.new("GR1", 1.0, 1)
    end
  end

  describe "new!/3" do
    test "returns the rule when valid" do
      assert %BuyXGetYFree{} = BuyXGetYFree.new!("GR1", 1, 1)
    end

    test "raises when amounts are invalid" do
      assert_raise ArgumentError, ~r/buy_amount and free_amount must be positive integers/, fn ->
        BuyXGetYFree.new!("GR1", 0, 1)
      end
    end
  end

  describe "BOGO (buy 1 get 1 free)" do
    test "does not apply below minimum quantity" do
      assert Rule.apply(bogo("GR1"), @green_tea, 0) == nil
    end

    test "1 item → no discount (cycle needs 2)" do
      assert Rule.apply(bogo("GR1"), @green_tea, 1) == nil
    end

    test "2 items → 1 free" do
      discount = Rule.apply(bogo("GR1"), @green_tea, 2)
      assert %Discount{amount: amount} = discount
      assert Money.equal?(amount, Money.new(:GBP, "3.11"))
    end

    test "3 items → 1 free (incomplete second cycle)" do
      discount = Rule.apply(bogo("GR1"), @green_tea, 3)
      assert %Discount{amount: amount} = discount
      assert Money.equal?(amount, Money.new(:GBP, "3.11"))
    end

    test "4 items → 2 free (two complete cycles)" do
      discount = Rule.apply(bogo("GR1"), @green_tea, 4)
      assert %Discount{amount: amount} = discount
      assert Money.equal?(amount, Money.new(:GBP, "6.22"))
    end

    test "discount carries the rule and product" do
      rule = bogo("GR1")
      product = @green_tea
      discount = Rule.apply(rule, product, 2)
      assert %Discount{rule: ^rule, product: ^product} = discount
    end

    test "does not apply to a different product" do
      assert Rule.apply(bogo("GR1"), @strawberry, 2) == nil
    end
  end

  describe "buy 2 get 1 free" do
    setup do
      {:ok, rule: BuyXGetYFree.new!("GR1", 2, 1)}
    end

    test "2 items → no discount (cycle needs 3)", %{rule: rule} do
      assert Rule.apply(rule, @green_tea, 2) == nil
    end

    test "3 items → 1 free", %{rule: rule} do
      discount = Rule.apply(rule, @green_tea, 3)
      assert %Discount{amount: amount} = discount
      assert Money.equal?(amount, Money.new(:GBP, "3.11"))
    end

    test "6 items → 2 free (two complete cycles)", %{rule: rule} do
      discount = Rule.apply(rule, @green_tea, 6)
      assert %Discount{amount: amount} = discount
      assert Money.equal?(amount, Money.new(:GBP, "6.22"))
    end
  end
end
