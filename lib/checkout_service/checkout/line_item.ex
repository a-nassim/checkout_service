defmodule CheckoutService.Checkout.LineItem do
  @moduledoc "A resolved cart entry carrying the product, quantity, and gross line total."

  alias CheckoutService.Catalog.Product
  alias CheckoutService.Checkout.Cart

  @typedoc "A line item on a receipt."
  @type t :: %__MODULE__{
          product: Product.t(),
          quantity: Cart.quantity(),
          line_total: Money.t()
        }

  @enforce_keys [:product, :quantity, :line_total]
  defstruct [:product, :quantity, :line_total]
end
