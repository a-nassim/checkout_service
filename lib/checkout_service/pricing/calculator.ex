defmodule CheckoutService.Pricing.Calculator do
  @moduledoc "Applies pricing rules to a cart and produces a `Receipt`."

  alias CheckoutService.Catalog
  alias CheckoutService.Checkout.Cart
  alias CheckoutService.Checkout.LineItem
  alias CheckoutService.Checkout.Receipt
  alias CheckoutService.Pricing.Rule

  @doc """
  Calculates the receipt for the given cart, rules, and catalog.

  For each product in the cart:
  - Resolves the product from the catalog
  - Builds a `LineItem` with the gross line total
  - Applies the first matching rule (if any), producing a `Discount`

  The subtotal is the sum of all line totals. The total is the subtotal minus
  all discounts.
  """
  @spec calculate(Cart.t(), [Rule.t()], Catalog.t()) :: Receipt.t()
  def calculate(%Cart{items: items}, rules, %Catalog{} = catalog) do
    zero = Money.zero(catalog.currency)

    {line_items, discounts, subtotal} =
      Enum.reduce(items, {[], [], zero}, fn {code, qty}, {li_acc, disc_acc, sub_acc} ->
        product = Catalog.fetch!(catalog, code)
        line_total = Money.mult!(product.price, qty)
        line_item = %LineItem{product: product, quantity: qty, line_total: line_total}
        discount = first_matching_rule(rules, product, qty)

        {
          [line_item | li_acc],
          if(discount, do: [discount | disc_acc], else: disc_acc),
          Money.add!(sub_acc, line_total)
        }
      end)

    total =
      Enum.reduce(discounts, subtotal, fn d, acc -> Money.sub!(acc, d.amount) end)
      |> Money.round()

    %Receipt{
      line_items: Enum.reverse(line_items),
      subtotal: subtotal,
      discounts: Enum.reverse(discounts),
      total: total
    }
  end

  # Returns the discount from the first rule that matches, or nil.
  defp first_matching_rule(rules, product, qty) do
    Enum.find_value(rules, fn rule -> Rule.apply(rule, product, qty) end)
  end
end
