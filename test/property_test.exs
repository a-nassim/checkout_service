defmodule CheckoutService.PropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias CheckoutService
  alias CheckoutService.Catalog
  alias CheckoutService.Pricing.Rule

  @pricing_rules [
    Rule.BuyXGetYFree.new!("GR1", 1, 1),
    Rule.BulkUnitPrice.new!("SR1", 3, Money.new(:GBP, "4.50"), Money.new(:GBP, "5.00")),
    Rule.BulkFractionPrice.new!("CF1", 3, {2, 3})
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

  defp subtotal(codes) do
    catalog = Catalog.default()

    Enum.reduce(codes, Money.zero(:GBP), fn code, acc ->
      {:ok, product} = Catalog.get(catalog, code)
      Money.add!(acc, product.price)
    end)
  end

  property "total <= subtotal for all baskets" do
    check all(codes <- list_of(one_of([constant("GR1"), constant("SR1"), constant("CF1")]))) do
      total = total(codes)
      subtotal = subtotal(codes)
      assert Money.compare(total, subtotal) != :gt
    end
  end

  property "total >= 0 for all baskets" do
    check all(codes <- list_of(one_of([constant("GR1"), constant("SR1"), constant("CF1")]))) do
      total = total(codes)
      assert Money.compare(total, money("0")) != :lt
    end
  end

  property "scan order independence" do
    check all(codes <- list_of(one_of([constant("GR1"), constant("SR1"), constant("CF1")]))) do
      total1 = total(codes)
      total2 = total(Enum.shuffle(codes))
      assert Money.equal?(total1, total2)
    end
  end

  property "adding items never decreases total" do
    check all(
            codes <- list_of(one_of([constant("GR1"), constant("SR1"), constant("CF1")])),
            extra_code <- one_of([constant("GR1"), constant("SR1"), constant("CF1")])
          ) do
      total_before = total(codes)
      total_after = total(codes ++ [extra_code])
      assert Money.compare(total_after, total_before) != :lt
    end
  end

  property "no rules means no discounts" do
    check all(codes <- list_of(one_of([constant("GR1"), constant("SR1"), constant("CF1")]))) do
      checkout = CheckoutService.new([])
      checkout = Enum.reduce(codes, checkout, &CheckoutService.scan!(&2, &1))
      receipt = CheckoutService.calculate(checkout)
      assert Money.equal?(receipt.total, receipt.subtotal)
      assert receipt.discounts == []
    end
  end
end
