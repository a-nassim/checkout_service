defmodule CheckoutService.Checkout do
  @moduledoc """
  Session struct holding a cart, pricing rules, and the catalog.

  The catalog is an explicit field rather than a global dependency so that
  different sessions can use different catalogs (e.g. in tests or multi-tenant
  scenarios) without any global state.
  """

  alias CheckoutService.Catalog
  alias CheckoutService.Checkout.Cart
  alias CheckoutService.Pricing.Rule

  @typedoc "An active checkout session."
  @type t :: %__MODULE__{
          cart: Cart.t(),
          rules: [Rule.t()],
          catalog: Catalog.t()
        }

  @enforce_keys [:rules, :catalog]
  defstruct [:catalog, cart: %Cart{}, rules: []]
end
