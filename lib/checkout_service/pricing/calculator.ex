defmodule CheckoutService.Pricing.Calculator do
  @moduledoc "Applies pricing rules to a cart and produces a `Receipt`."

  alias CheckoutService.Catalog
  alias CheckoutService.Checkout.Cart
  alias CheckoutService.Checkout.LineItem
  alias CheckoutService.Checkout.Receipt
  alias CheckoutService.Pricing.Rule

  @doc """
  Calculates the receipt for the given cart, rules, and catalog.
  """
  @spec calculate(Cart.t(), [Rule.t()], Catalog.t()) :: Receipt.t()
  def calculate(%Cart{items: items}, _rules, %Catalog{} = catalog) do
    zero = Money.zero(catalog.currency)

    {line_items, total = subtotal} =
      Enum.reduce(items, {[], zero}, fn {code, qty}, {line_items, subtotal} ->
        product = Catalog.fetch!(catalog, code)
        line_total = Money.mult!(product.price, qty)
        line_item = %LineItem{product: product, quantity: qty, line_total: line_total}

        {
          [line_item | line_items],
          Money.add!(subtotal, line_total)
        }
      end)

    %Receipt{
      line_items: Enum.reverse(line_items),
      subtotal: subtotal,
      discounts: [],
      total: total
    }
  end
end
