defmodule CheckoutService do
  @moduledoc "Public API for the checkout service."

  alias CheckoutService.Catalog
  alias CheckoutService.Catalog.Product
  alias CheckoutService.Checkout
  alias CheckoutService.Checkout.Receipt
  alias CheckoutService.Pricing.Calculator
  alias CheckoutService.Pricing.Rule

  @doc """
  Creates a new checkout session with the given pricing rules.

  `catalog` defaults to `Catalog.default/0` (GR1, SR1, CF1) but can be
  overridden for tests or multi-tenant scenarios.

      checkout = CheckoutService.new(rules)
      checkout = CheckoutService.new(rules, custom_catalog)
  """
  @spec new([Rule.t()], Catalog.t()) :: Checkout.t()
  def new(pricing_rules, catalog \\ Catalog.default()) do
    %Checkout{rules: pricing_rules, catalog: catalog}
  end

  @doc "Scans a product into the checkout by its product code."
  @spec scan(Checkout.t(), Product.code()) ::
          {:ok, Checkout.t()} | {:error, :unknown_product}
  def scan(%Checkout{} = checkout, product_code) do
    case Catalog.get(checkout.catalog, product_code) do
      {:ok, product} ->
        {:ok, checkout |> Map.update!(:cart, &Checkout.Cart.add(&1, product.code))}

      {:error, :not_found} ->
        {:error, :unknown_product}
    end
  end

  @doc """
  Scans a product into the checkout by its product code, raising on unknown codes.
  """
  @spec scan!(Checkout.t(), Product.code()) :: Checkout.t()
  def scan!(checkout, product_code) do
    case scan(checkout, product_code) do
      {:ok, checkout} -> checkout
      {:error, reason} -> raise ArgumentError, "cannot scan product #{product_code}: #{reason}"
    end
  end

  @doc "Removes one unit of a product from the checkout by its product code."
  @spec remove(Checkout.t(), Product.code()) ::
          {:ok, Checkout.t()} | {:error, :not_in_cart}
  def remove(%Checkout{} = checkout, product_code) do
    case Checkout.Cart.remove(checkout.cart, product_code) do
      {:ok, cart} -> {:ok, %{checkout | cart: cart}}
      {:error, :not_in_cart} -> {:error, :not_in_cart}
    end
  end

  @doc """
  Removes one unit of a product from the checkout, raising on unknown codes.
  """
  @spec remove!(Checkout.t(), Product.code()) :: Checkout.t()
  def remove!(checkout, product_code) do
    case remove(checkout, product_code) do
      {:ok, checkout} -> checkout
      {:error, reason} -> raise ArgumentError, "cannot remove product #{product_code}: #{reason}"
    end
  end

  @doc "Clears all scanned products from the checkout cart."
  @spec clear(Checkout.t()) :: Checkout.t()
  def clear(%Checkout{} = checkout) do
    %{checkout | cart: Checkout.Cart.clear(checkout.cart)}
  end

  @doc "Applies pricing rules to the cart and returns an auditable `Receipt`."
  @spec calculate(Checkout.t()) :: Receipt.t()
  def calculate(%Checkout{} = checkout) do
    Calculator.calculate(checkout.cart, checkout.rules, checkout.catalog)
  end
end
