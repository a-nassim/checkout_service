defmodule CheckoutService.Catalog do
  @moduledoc """
  A lookup table of products keyed by product code, scoped to a single currency.

  The catalog is an explicit dependency of a checkout session rather than
  global state, making it easy to swap in a custom catalog for tests or
  multi-tenant scenarios.

      catalog = CheckoutService.Catalog.new(:GBP, [%Product{code: "GR1", ...}])
      checkout = CheckoutService.new(rules, catalog)
  """

  alias CheckoutService.Catalog.Product

  # Currency codes are atoms (e.g. :GBP) as used by ex_money.
  @type currency :: atom()

  @typedoc "A catalog mapping product codes to products, scoped to a single currency."
  @type t :: %__MODULE__{
          currency: currency(),
          products: %{Product.code() => Product.t()}
        }

  @enforce_keys [:currency, :products]
  defstruct [:currency, :products]

  @doc """
  Builds a catalog from a currency and a list of `Product` structs.

  Returns `{:error, :currency_mismatch}` if any product's price does not match
  the declared currency.
  """
  @spec new(currency(), [Product.t()]) :: {:ok, t()} | {:error, :currency_mismatch}
  def new(currency, products) when is_list(products) do
    case Enum.find(products, &(&1.price.currency != currency)) do
      nil ->
        index = Map.new(products, fn %Product{code: code} = p -> {code, p} end)
        {:ok, %__MODULE__{currency: currency, products: index}}

      _ ->
        {:error, :currency_mismatch}
    end
  end

  @doc """
  Looks up a product by code.

  Returns `{:ok, product}` if found, `{:error, :not_found}` otherwise.
  """
  @spec get(t(), Product.code()) :: {:ok, Product.t()} | {:error, :not_found}
  def get(%__MODULE__{products: products}, code) do
    case Map.fetch(products, code) do
      {:ok, product} -> {:ok, product}
      :error -> {:error, :not_found}
    end
  end

  @doc "Returns the standard catalog pre-loaded with the three known products."
  @spec default() :: t()
  def default do
    {:ok, catalog} =
      new(:GBP, [
        %Product{code: "GR1", name: "Green tea", price: Money.new(:GBP, "3.11")},
        %Product{code: "SR1", name: "Strawberries", price: Money.new(:GBP, "5.00")},
        %Product{code: "CF1", name: "Coffee", price: Money.new(:GBP, "11.23")}
      ])

    catalog
  end
end
