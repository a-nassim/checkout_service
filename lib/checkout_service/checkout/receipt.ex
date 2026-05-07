defmodule CheckoutService.Checkout.Receipt do
  @moduledoc """
  The auditable result of `CheckoutService.calculate/1`.

  Contains the final `total`, the gross `subtotal` before discounts, the
  `line_items` showing what was bought, and the `discounts` that were applied.
  """

  alias CheckoutService.Checkout.LineItem
  alias CheckoutService.Pricing.Discount

  @typedoc "The auditable result of a checkout calculation."
  @type t :: %__MODULE__{
          line_items: [LineItem.t()],
          subtotal: Money.t(),
          discounts: [Discount.t()],
          total: Money.t()
        }

  @enforce_keys [:line_items, :subtotal, :discounts, :total]
  defstruct [:line_items, :subtotal, :discounts, :total]
end
