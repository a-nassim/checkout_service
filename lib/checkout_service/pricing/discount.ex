defmodule CheckoutService.Pricing.Discount do
  @moduledoc "A discount applied to a product by a pricing rule, carried by a `Receipt`."

  alias CheckoutService.Catalog.Product
  alias CheckoutService.Pricing.Rule

  @typedoc "A discount applied to a product by a pricing rule."
  @type t :: %__MODULE__{
          rule: Rule.t(),
          product: Product.t(),
          amount: Money.t()
        }

  @enforce_keys [:rule, :product, :amount]
  defstruct [:rule, :product, :amount]
end
