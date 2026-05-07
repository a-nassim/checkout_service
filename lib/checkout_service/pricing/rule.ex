defprotocol CheckoutService.Pricing.Rule do
  @moduledoc """
  Protocol for pricing rules.

  Each rule is evaluated per product. It receives the resolved `Product` and
  its quantity in the cart, and returns a `Discount` if it applies or `nil`
  if it does not.

  Rules are evaluated in the order they are passed to `CheckoutService.new/2`.
  Only the first matching rule per product is applied — subsequent rules
  targeting the same product are skipped.
  """

  alias CheckoutService.Catalog.Product
  alias CheckoutService.Checkout.Cart
  alias CheckoutService.Pricing.Discount

  @doc """
  Evaluates the rule for a single product and its cart quantity.

  Returns a `Discount` if the rule applies, `nil` otherwise.
  """
  @spec apply(t(), Product.t(), Cart.quantity()) :: Discount.t() | nil
  def apply(rule, product, quantity)
end
