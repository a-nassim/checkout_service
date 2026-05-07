defmodule CheckoutService.Pricing.Calculator do
  @moduledoc "Applies pricing rules to a cart and produces a `Receipt`."

  alias CheckoutService.Catalog
  alias CheckoutService.Checkout.Cart
  alias CheckoutService.Checkout.Receipt
  alias CheckoutService.Pricing.Rule

  @doc """
  Calculates the receipt for the given cart, rules, and catalog.
  """
  @spec calculate(Cart.t(), [Rule.t()], Catalog.t()) :: Receipt.t()
  def calculate(%Cart{} = cart, _rules, %Catalog{} = catalog) do
    total = subtotal = subtotal(cart, catalog)

    %Receipt{subtotal: subtotal, total: total, discounts: []}
  end

  defp subtotal(%Cart{items: items}, catalog) do
    Enum.reduce(items, Money.zero(catalog.currency), fn {code, qty}, sum ->
      product = Catalog.fetch!(catalog, code)

      product.price
      |> Money.mult!(qty)
      |> Money.add!(sum)
    end)
  end
end
