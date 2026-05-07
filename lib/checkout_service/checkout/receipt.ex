defmodule CheckoutService.Checkout.Receipt do
  @moduledoc """
  The auditable result of `CheckoutService.calculate/1`.

  Contains the final `total`, the gross `subtotal` before discounts, and the
  list of `Discount`s that were applied.
  """

  alias CheckoutService.Pricing.Discount

  @typedoc "The auditable result of a checkout calculation."
  @type t :: %__MODULE__{
          total: Money.t(),
          subtotal: Money.t(),
          discounts: [Discount.t()]
        }

  @enforce_keys [:total, :subtotal, :discounts]
  defstruct [:total, :subtotal, :discounts]
end
