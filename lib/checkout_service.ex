defmodule CheckoutService do
  @moduledoc "Public API for the checkout service."

  alias CheckoutService.Catalog
  alias CheckoutService.Catalog.Product
  alias CheckoutService.Checkout
  alias CheckoutService.Checkout.Receipt
  alias CheckoutService.Pricing.Rule

  @doc """
  Creates a new checkout session with the given pricing rules.

  `catalog` defaults to `Catalog.default/0` (GR1, SR1, CF1) but can be
  overridden for tests or multi-tenant scenarios.

      checkout = CheckoutService.new(rules)
      checkout = CheckoutService.new(rules, custom_catalog)
  """
  @spec new([Rule.t()], Catalog.t()) :: Checkout.t()
  def new(_pricing_rules, _catalog \\ Catalog.default()) do
    raise "not implemented"
  end

  @doc "Scans a product into the checkout by its product code."
  @spec scan(Checkout.t(), Product.code()) ::
          {:ok, Checkout.t()} | {:error, :unknown_product}
  def scan(_checkout, _product_code) do
    raise "not implemented"
  end

  @doc """
  Scans a product into the checkout by its product code, raising on unknown codes.
  """
  @spec scan!(Checkout.t(), Product.code()) :: Checkout.t()
  def scan!(_checkout, _product_code) do
    raise "not implemented"
  end

  @doc "Applies pricing rules to the cart and returns an auditable `Receipt`."
  @spec calculate(Checkout.t()) :: Receipt.t()
  def calculate(_checkout) do
    raise "not implemented"
  end
end
